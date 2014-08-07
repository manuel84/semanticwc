# Eine Anwendung für die FIFA Fußball-Weltmeisterschaft mit ”Semantic Web”-Technologien

Dies ist ein Projekt, gestartet im Rahmen der Lehrveranstaltung "Informationsverarbeitung im Semantic Web" der Hochschule RheinMain.

Das zugehörige Paper findet man unter [https://github.com/manuel84/semanticwc/blob/master/doc/Paper/paper_sem_web.pdf](https://github.com/manuel84/semanticwc/blob/master/doc/Paper/paper_sem_web.pdf).

Die zugehörige Web-Anwendung ist mobil optimiert: [http://semanticwc.herokuapp.com/](http://semanticwc.herokuapp.com/).

## Dokumentation
Man kann die Dokumentation einsehen unter "/doc/index.html".

Die Sparql-Abfragen sind im {RdfHelper}.

## Getting started
Semanticwc ist ein [Ruby on Rails](https://github.com/rails/rails)-Projekt. Es gelten daher die üblichen Installationsanweisungen.
Das Projekt arbeitet allerdings ohne Datenbank. Man muss lediglich das RDF-Repository bilden mit:

`rake semanticwc:build`

## Team

- Entwickler: [Manuel Dudda](http://manuel.dudda-und-dudda.de), [Robert Brylka](mailto:robert.brylka@email.de), [Frank Reichwein](mailto:frank.reichwein@gmail.com)

## License

Ruby on Rails is released under the [MIT License](http://opensource.org/licenses/MIT).