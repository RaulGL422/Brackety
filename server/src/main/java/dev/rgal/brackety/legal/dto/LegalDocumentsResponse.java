package dev.rgal.brackety.legal.dto;

import java.util.List;

public record LegalDocumentsResponse(List<Document> documents, boolean privacyContactConfigured) {

    public record Document(String type, String version, boolean acceptanceRequired) {}
}
