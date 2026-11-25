package dev.rgal.brackety.common;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.UrlPathHelper;

// The multipart limits (application.properties) do not cover a raw body: a byte[] or JSON body is read whole into
// memory before the controller checks who sends it, so any signed-in account could send gigabytes and take the
// server down. Right after the rate limiter, before any token work.
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 1)
class RequestSizeFilter extends OncePerRequestFilter {

    static final long DEFAULT_LIMIT = 2L * 1024 * 1024;
    // A results file is a zip with a package of up to 50 MB (EventPackageService).
    static final long RESULTS_LIMIT = 60L * 1024 * 1024;
    static final long OFFLINE_OPS_LIMIT = 10L * 1024 * 1024;

    private static final UrlPathHelper PATHS = UrlPathHelper.defaultInstance;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        var type = request.getContentType();
        return type != null && type.toLowerCase().startsWith(MediaType.MULTIPART_FORM_DATA_VALUE);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        var limit = limitFor(PATHS.getPathWithinApplication(request));
        if (request.getContentLengthLong() > limit) {
            ProblemResponses.write(response, HttpStatus.CONTENT_TOO_LARGE, "The request body is too large.");
            return;
        }
        // Without a Content-Length (chunked) the size is only known while reading: stop there.
        chain.doFilter(new LimitedRequest(request, limit), response);
    }

    static long limitFor(String path) {
        if (path.endsWith("/import/results")) {
            return RESULTS_LIMIT;
        }
        if (path.endsWith("/offline-ops/import")) {
            return OFFLINE_OPS_LIMIT;
        }
        return DEFAULT_LIMIT;
    }

    private static final class LimitedRequest extends HttpServletRequestWrapper {

        private final long limit;
        private ServletInputStream stream;

        LimitedRequest(HttpServletRequest request, long limit) {
            super(request);
            this.limit = limit;
        }

        @Override
        public ServletInputStream getInputStream() throws IOException {
            if (stream == null) {
                stream = new LimitedStream(super.getInputStream(), limit);
            }
            return stream;
        }
    }

    private static final class LimitedStream extends ServletInputStream {

        private final ServletInputStream in;
        private final long limit;
        private long read;

        LimitedStream(ServletInputStream in, long limit) {
            this.in = in;
            this.limit = limit;
        }

        @Override
        public int read() throws IOException {
            var b = in.read();
            if (b >= 0) {
                count(1);
            }
            return b;
        }

        @Override
        public int read(byte[] buffer, int offset, int length) throws IOException {
            var n = in.read(buffer, offset, length);
            if (n > 0) {
                count(n);
            }
            return n;
        }

        private void count(int n) throws IOException {
            read += n;
            if (read > limit) {
                throw new IOException("The request body is larger than " + limit + " bytes");
            }
        }

        @Override
        public boolean isFinished() {
            return in.isFinished();
        }

        @Override
        public boolean isReady() {
            return in.isReady();
        }

        @Override
        public void setReadListener(ReadListener listener) {
            in.setReadListener(listener);
        }
    }
}
