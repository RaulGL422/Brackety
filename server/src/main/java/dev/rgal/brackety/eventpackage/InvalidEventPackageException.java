package dev.rgal.brackety.eventpackage;

/** The message names the problem and where (field, row index), never personal data. */
public class InvalidEventPackageException extends RuntimeException {

    InvalidEventPackageException(String message) {
        super(message);
    }
}
