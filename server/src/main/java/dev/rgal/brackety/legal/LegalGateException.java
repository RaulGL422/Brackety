package dev.rgal.brackety.legal;

import org.springframework.http.HttpStatus;
import org.springframework.web.ErrorResponseException;

/** 403 {@code LEGAL_GATE}: without a privacy contact nobody could exercise their rights over the data. */
class LegalGateException extends ErrorResponseException {

    LegalGateException() {
        super(HttpStatus.FORBIDDEN);
        setDetail("Set PRIVACY_CONTACT_EMAIL before starting or creating a phase.");
        getBody().setProperty("code", "LEGAL_GATE");
    }
}
