/// An extractor that can manage both multipart and simple POST requests.
use async_trait::async_trait;
use axum::{
    extract::{BodyStream, FromRequest, Multipart},
    http::header::{HeaderMap, CONTENT_TYPE},
    response::{IntoResponse, Response},
    BoxError, RequestExt,
};
use bytes::Bytes;
use http::Request;
use hyper::body::HttpBody;

#[derive(Debug)]
pub enum MaybeMultipart {
    Single(BodyStream),
    Multiple(Multipart),
}

fn is_multipart(headers: &HeaderMap) -> bool {
    if let Some(content_type) = headers.get(CONTENT_TYPE) {
        if let Ok(content_type) = content_type.to_str() {
            return multer::parse_boundary(content_type).ok().is_some();
        }
    }

    false
}

#[async_trait]
impl<S, B> FromRequest<S, B> for MaybeMultipart
where
    B: HttpBody + Send + 'static,
    B::Data: Into<Bytes>,
    B::Error: Into<BoxError>,
    S: Send + Sync,
{
    type Rejection = Response;

    async fn from_request(req: Request<B>, _state: &S) -> Result<Self, Self::Rejection> {
        Ok(if is_multipart(req.headers()) {
            let multipart: Multipart = req.extract().await.map_err(IntoResponse::into_response)?;
            Self::Multiple(multipart)
        } else {
            let body: BodyStream = req.extract().await.map_err(IntoResponse::into_response)?;
            Self::Single(body)
        })
    }
}
