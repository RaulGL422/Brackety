package dev.rgal.brackety.participant.importing;

/** A photo of a list (image media type) or its text (CSV, TXT, an Excel sheet or pasted text). */
record ListFile(String mediaType, byte[] content) {

    boolean isImage() {
        return mediaType.startsWith("image/");
    }
}
