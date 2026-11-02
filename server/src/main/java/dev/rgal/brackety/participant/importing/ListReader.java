package dev.rgal.brackety.participant.importing;

import dev.rgal.brackety.participant.importing.dto.ImportRow;
import java.util.List;

/** Reads the participants of a list; the server checks every row afterwards. */
interface ListReader {

    /** False when the server has no way to read lists (no Anthropic key). */
    boolean isAvailable();

    /** @throws ListReadException when the list cannot be read */
    List<ImportRow> read(List<ListFile> files);
}
