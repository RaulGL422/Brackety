/// Only the web build can save files; the export buttons are hidden elsewhere.
void saveFile(String name, List<int> bytes, String mimeType) =>
    throw UnsupportedError('Saving files is only available on the web.');
