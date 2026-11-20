package dev.rgal.brackety.auth;

import dev.rgal.brackety.auth.session.SessionService.Session;

/**
 * Signs in with the code of a QR the club showed (staff.TemporaryAccessService): the account is temporary, tied to
 * one event, and the code works once.
 */
public interface TemporarySignIn {

    Session signIn(String token);
}
