package dev.rgal.brackety.auth.dto;

/** A legal text whose version changed since this account accepted it: {@code document} as its slug (terms, privacy). */
public record PendingConsent(String document, String version) {}
