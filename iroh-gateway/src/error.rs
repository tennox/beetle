use std::{
    error::Error,
    fmt::{self, Display, Formatter},
};

use axum::{
    body::BoxBody,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use http::HeaderMap;
use serde_json::json;

#[derive(Debug, Clone)]
pub struct GatewayError {
    pub status_code: StatusCode,
    pub message: String,
    pub method: Option<http::Method>,
    pub accept_html: bool,
}

impl GatewayError {
    pub fn new(status_code: StatusCode, message: &str) -> GatewayError {
        GatewayError {
            status_code,
            message: message.to_string(),
            method: None,
            accept_html: false,
        }
    }

    pub fn with_method(self, method: http::Method) -> Self {
        Self {
            method: Some(method),
            ..self
        }
    }

    pub fn with_html(self) -> Self {
        Self {
            accept_html: true,
            ..self
        }
    }
}

impl IntoResponse for GatewayError {
    fn into_response(self) -> Response {
        let headers = HeaderMap::new();
        match self.method {
            Some(http::Method::HEAD) => {
                let mut rb = Response::builder().status(self.status_code);
                let rh = rb.headers_mut().unwrap();
                rh.extend(headers);
                rb.body(BoxBody::default()).unwrap()
            }
            _ => {
                let body = axum::Json(json!({
                    "code": self.status_code.as_u16(),
                    "success": false,
                    "message": self.message,
                }));
                let mut res = body.into_response();
                if self.accept_html && self.status_code == StatusCode::NOT_FOUND {
                    let body = crate::templates::NOT_FOUND_TEMPLATE;
                    res = body.into_response();
                    res.headers_mut().insert(
                        http::header::CONTENT_TYPE,
                        http::header::HeaderValue::from_static("text/html"),
                    );
                }
                res.headers_mut().extend(headers);
                let status = res.status_mut();
                *status = self.status_code;
                res
            }
        }
    }
}

impl Display for GatewayError {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "gateway_error({}): {})",
            &self.status_code, &self.message
        )
    }
}

impl Error for GatewayError {}
