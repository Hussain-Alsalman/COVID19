#COVID19 Simulation
An [ABM](https://en.wikipedia.org/wiki/Agent-based_model) using [GAMA-Platform](https://gama-platform.github.io/) aims at simulating people of Al-Mubarraz city behavior under two scenarios; namely "compliance" and noncompliance" with the new government directions to slow down the spread of COVID19.

## Objective
The objective of the model is to determine the factors that has the most impact on "flattening the curve" of the infection. More specifically, the model is designed to answer the following questions.

- What is the baseline rate of infection with no restrictions applied?
- What is the impact of only staying at home during the lock-down hours?
- What is the impact of delegating one person for each family to do groceries and essential things?
- What is the impact of early and quick detection and isolation of infected people?

*Results and discussion of the simulation is coming soon in the Arabian Analyst blog.*

## Assumptions
I have made several simplifying assumptions about the simulating environment and agents within it for two reasons:

- lack of detailed societal studies and description
- lack of high computing power that is required for high fidelity models.

### Environment

#### General assumptions
- The simulation starts at the date of 2nd of April 2020.
- The step size of the simulation is 60 minutes i.e agents are simulated every hour in the timeline.

#### Population
-`nb_people`: the population size is set to `1000`
-`nb_infected_init` the initially infected people is set to `10` which only accounts for 1% of the population.

#### Infection, Recovery and health assumptions.
- For simplicity, I have assumed that the mortality rate is zero, meaning all infected people will get recovered eventually.
- `infect_range` the distance in which a susceptible person will be at risk of getting infected. Default value is 4 meters.
- SIR model was used with `gama` value of 1/20160 (i.e 14 days to recover). on the other hand, `beta` was set to 0.05.

### Individuals

#### Attributes
- Every individual has a favorite places near him that he visit based on location proximity (mosque, supermarket bank and shops).
- An individual is either susceptible, infected or recovered.
- individual's objective determines his behavior.

#### Behavior
- Each individual starts his day within a random range between 5:00AM to 8:00AM and ends his day between 6:00PM to 10:00PM.
- Each individual has different day schedule and agenda.

### Containment policies
The model assumed the following containment policies
- Setting Curfew. Starting from 7:00PM to 6:00AM all week days.
- Active Testing.
- Detection and Isolation with success rate 10%.  
- Cancellation of Congregational prayer for all the five prayer times.

## Data Sources
Sources:
- Streets and POI: [OpenStreetMap](https://www.openstreetmap.org).
- Residential Buildings : web scraping + satellite image processing.

## Included Files
- `all_buildings.shp` includes most of residential buildings and POI in Al Mubarraz city.
- `roadsplus.shp`  includes all types of roads of Al Mubarraz city.
