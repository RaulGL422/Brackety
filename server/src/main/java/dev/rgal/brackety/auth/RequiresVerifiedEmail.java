package dev.rgal.brackety.auth;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import org.springframework.security.access.prepost.PreAuthorize;

/** For endpoints that create something of value: an account with an unverified email gets 403. */
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@PreAuthorize("hasAuthority('" + SecurityConfig.EMAIL_VERIFIED + "')")
public @interface RequiresVerifiedEmail {}
