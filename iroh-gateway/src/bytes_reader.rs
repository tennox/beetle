// An AsyncRead implementation for Bytes

use bytes::Bytes;
use std::io;
use std::pin::Pin;
use std::task::{Context, Poll};
use tokio::io::{AsyncRead, ReadBuf};

#[derive(Debug)]
pub struct BytesReader {
    bytes: Bytes,
    pos: usize,
}

impl BytesReader {
    pub fn new(bytes: Bytes) -> Self {
        Self { bytes, pos: 0 }
    }
}

impl AsyncRead for BytesReader {
    fn poll_read(
        self: Pin<&mut Self>,
        _cx: &mut Context<'_>,
        buf: &mut ReadBuf<'_>,
    ) -> Poll<io::Result<()>> {
        let mut inner = self.get_mut();
        let remaining = inner.bytes.len() - inner.pos;
        if remaining == 0 {
            return Poll::Ready(Ok(()));
        }
        let n = std::cmp::min(buf.remaining(), remaining);
        buf.put_slice(&inner.bytes[inner.pos..inner.pos + n]);
        inner.pos += n;
        Poll::Ready(Ok(()))
    }
}
