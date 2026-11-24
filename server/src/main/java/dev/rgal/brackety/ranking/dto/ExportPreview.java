package dev.rgal.brackety.ranking.dto;

import java.util.List;

/** The first rows of an export as the file will write them, and how many rows it has in all. */
public record ExportPreview(List<String> headers, List<List<String>> rows, int totalRows) {}
