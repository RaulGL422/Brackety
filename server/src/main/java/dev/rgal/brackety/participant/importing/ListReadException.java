package dev.rgal.brackety.participant.importing;

class ListReadException extends RuntimeException {

    ListReadException(String message) {
        super(message);
    }

    ListReadException(String message, Throwable cause) {
        super(message, cause);
    }
}
