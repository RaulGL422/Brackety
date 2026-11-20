-- Rules general enough for other sports (docs/producto/grappling.md, G2d): the warnings as a ladder of points for the
-- rival, the actions that win at once by name, and the tiebreaks as an ordered list.
update modality
set scoring = (scoring - 'warningsPerRivalPoint' - 'submissions' - 'tiebreaks')
    || jsonb_build_object(
        'warningPoints',
        (select jsonb_agg(case when i = (scoring ->> 'warningsPerRivalPoint')::int then 1 else 0 end order by i)
         from generate_series(1, (scoring ->> 'warningsPerRivalPoint')::int) i),
        'finishes',
        case when (scoring ->> 'submissions')::boolean then '["Sumisión"]'::jsonb else '[]'::jsonb end,
        'tiebreaks',
        case when (scoring ->> 'tiebreaks')::boolean
            then '["BEST_ACTION", "FEWER_WARNINGS", "EXTRA_TIME"]'::jsonb else '[]'::jsonb end)
where scoring ? 'warningsPerRivalPoint';
