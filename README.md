# Far-Right Party Analysis
This repository contains an analysis of far-right parties across different countries.

### Data Sources
The full dataset is available in the `data` directory of this repository as `full_data.csv`.

#### Election Results
Election results are sourced from [ParlGov](https://parlgov.org/) through mid-2023, while results from mid-2023 onward have been compiled by us using official national sources. 

The data only include parties that either got at least 1% of the votes or one seat in parliament. The remaining votes are aggregated under "Other".

#### Far-Right Classification
Far-right classification follows [PopuList](https://populist.org/), a peer-reviewed list of far-right parties in Europe. 

We have made a few changes to PopuList's classifications.
Where far-right parties have run as part of a coalition (e.g., Law and Justice in Poland), the coalition is classified as far-right if its lead party is. 

A small number of newer parties not yet covered by PopuList have also been classified as far-right by us.

These parties are: Fidesz -- Hungarian Civic Party / Christian Democratic People's Party (Hungary), United Right (Poland), The Citizens' Party (Denmark), Greatness (Bulgaria), S.O.S Romania (Romania), Party of Young People (Romania), Motorists (Czech Republic), People and Justice Union (Lithuania) and Republic Movement (Slovakia).

### Analysis
The analysis is limited to EU member states plus the UK, Norway, and Switzerland, and covers parliamentary elections only, excluding local, EU, and presidential elections. Results are restricted to elections held in 1994 or later. 

Because PopuList also records when a party became or stopped being classified as far-right, we only treat a party as far-right for the election years that fall within that window, rather than applying the label retroactively or after it ceased to qualify. 

Since ParlGov only reports parties that won at least one seat or at least 1% of the vote, vote shares in the raw data don't sum to 100%, so we add an "Other" category per country and election to absorb the remainder and ensure totals always reach 100%. 