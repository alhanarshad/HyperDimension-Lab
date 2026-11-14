# Trail Grade

A static, browser-local elevation profile inspector. Paste sampled distance and elevation to see grades, ascent and descent, and the segments that cross a threshold. The canvas and table report the same data. There are no accounts, network requests, or dependencies.

```sh
python -m http.server 8000
node --test profile.test.mjs
```

Open `http://localhost:8000`. Each input line is `distance_m,elevation_m`, strictly increasing by distance. Blank lines and lines starting with `#` are allowed. Grade is signed elevation difference divided by horizontal distance, multiplied by 100. The steepness threshold uses the absolute grade.

The example is synthetic. Wide sample spacing may miss local grade changes. The tool takes horizontally measured distances and does not infer them from latitude and longitude.
