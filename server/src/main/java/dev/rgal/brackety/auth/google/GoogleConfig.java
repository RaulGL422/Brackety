package dev.rgal.brackety.auth.google;

import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.JWKSourceBuilder;
import com.nimbusds.jose.proc.SecurityContext;
import java.net.MalformedURLException;
import java.net.URI;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
class GoogleConfig {

    static final String JWKS_URI = "https://www.googleapis.com/oauth2/v3/certs";

    // Google's public keys, fetched on first use and cached. Tests and the local runner replace this bean.
    @Bean
    JWKSource<SecurityContext> googleJwks() throws MalformedURLException {
        return JWKSourceBuilder.<SecurityContext>create(URI.create(JWKS_URI).toURL())
                .build();
    }
}
