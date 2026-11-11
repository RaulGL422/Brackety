package dev.rgal.brackety.ranking;

import dev.rgal.brackety.event.EventService;
import dev.rgal.brackety.eventpackage.EventPackageService;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.json.JsonMapper;

/**
 * Everything about an event in one .zip: sheets for Excel, the event package (to load it on the hall server or bring
 * its results back) and a LEEME.txt that explains each file.
 */
@Service
class FullExportService {

    private static final String README = """
            Exportación completa de un evento de Brackety
            ==============================================

            Los ficheros .csv se abren con Excel (doble clic) o LibreOffice: columnas separadas por punto y coma,
            UTF-8 con BOM, fechas dd/mm/aaaa y tiempos en m:ss.

            participantes.csv       Un alumno por fila: datos, club, edad el día del evento, categoría,
                                    consentimiento del tutor, equipo, grupo y tapiz.
            categorias.csv          Categorías con sus edades, formato, inscritos, grupos y podio
                                    (cuántos primeros, segundos y terceros).
            tapices.csv             Tapices con su árbitro y cuántos grupos y combates tuvieron.
            grupos.csv              Una fila por miembro de cada grupo (alumno o equipo), en su orden,
                                    con el fantasma marcado.
            combates.csv            Cada combate: grupo, tapiz, rojo y azul con su club, puntos, ganador,
                                    cómo acabó, horas y tiempo de combate.
            linea-de-tiempo.csv     Cada acción del árbitro en cada combate, en orden, con la hora y el
                                    reloj del combate; las deshechas están marcadas.
            clasificacion-fase.csv  Puntuación de esta fase: asistencia + puntos en combates.
            clasificacion-liga.csv  Puntuación acumulada de la liga por categoría, con una columna por
                                    fase, el total y la medalla según el podio configurado.
            evento.brackety         El evento completo en JSON (configuración, inscritos y resultados):
                                    sirve para arrancar el servidor del pabellón
                                    (start-event.ps1 -Package <este .zip>) o para importar los
                                    resultados en el servidor del club (Panel del club > Importar resultados).

            Contiene datos personales de menores: guárdalo solo donde haga falta y bórralo cuando ya no.
            """;

    private final EventSheets sheets;
    private final StandingsService standings;
    private final LeagueStandingsService leagueStandings;
    private final EventPackageService packages;
    private final EventService events;
    private final JsonMapper json;

    FullExportService(
            EventSheets sheets,
            StandingsService standings,
            LeagueStandingsService leagueStandings,
            EventPackageService packages,
            EventService events,
            JsonMapper json) {
        this.sheets = sheets;
        this.standings = standings;
        this.leagueStandings = leagueStandings;
        this.packages = packages;
        this.events = events;
        this.json = json;
    }

    record Export(String filename, byte[] zip) {}

    @Transactional(readOnly = true)
    Export export(UUID eventId, UUID accountId) {
        var eventPackage = packages.export(eventId, accountId);
        var event = events.get(eventId);
        var files = new LinkedHashMap<String, byte[]>();
        files.put("LEEME.txt", text(Csv.BOM + README.replace("\n", "\r\n")));
        files.put("participantes.csv", text(sheets.participantsCsv(eventId, accountId)));
        files.put(
                "categorias.csv",
                text(sheets.categoriesCsv(eventId, accountId, leagueStandings.podiums(event.getLeagueId()))));
        files.put("tapices.csv", text(sheets.matsCsv(eventId, accountId)));
        files.put("grupos.csv", text(sheets.groupsCsv(eventId, accountId)));
        files.put("combates.csv", text(sheets.matchesCsv(eventId, accountId)));
        files.put("linea-de-tiempo.csv", text(sheets.timelineCsv(eventId, accountId)));
        files.put("clasificacion-fase.csv", text(standings.standingsCsv(eventId, accountId)));
        files.put("clasificacion-liga.csv", text(leagueStandings.csv(eventId, accountId)));
        files.put(
                EventPackageService.ZIP_ENTRY,
                json.writerWithDefaultPrettyPrinter().writeValueAsBytes(eventPackage));
        var filename = EventPackageService.fileName(event) + ".zip";
        return new Export(filename, zip(files));
    }

    private static byte[] text(String content) {
        return content.getBytes(StandardCharsets.UTF_8);
    }

    private static byte[] zip(LinkedHashMap<String, byte[]> files) {
        var out = new ByteArrayOutputStream();
        try (var zip = new ZipOutputStream(out, StandardCharsets.UTF_8)) {
            for (var file : files.entrySet()) {
                zip.putNextEntry(new ZipEntry(file.getKey()));
                zip.write(file.getValue());
                zip.closeEntry();
            }
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return out.toByteArray();
    }
}
