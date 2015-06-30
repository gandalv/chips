// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:math';
import 'dart:async';

FacilityLocation facilityLocation;

void main() {
  facilityLocation = new FacilityLocation('vertex-cover');
}

class City {
  double x;
  double y;
  int id;

  City(this.x, this.y, this.id) {

  }
}

class Individual {
  List<bool> genotype;
  double fitness;


  Individual(this.genotype, this.fitness) {

  }

  String toString() {
    return genotype.map((bool b) => b ? "1" : 0).join();
  }

  Individual clone() {
    return new Individual(new List.from(genotype), fitness);
  }
}

class FacilityLocation {
  CanvasElement canvas;
  CanvasRenderingContext2D ctx;
  ButtonElement startButton;
  ButtonElement cancelButton;
  ButtonElement resetButton;
  InputElement facilityCostInput;
  InputElement popSizeInput;
  InputElement xoverProbInput;
  InputElement mutProbInput;
  InputElement tournamentSizeInput;
  DivElement genDiv;
  DivElement fitDiv;
  List<City> cities;

  num modelWidth = 100;
  num modelHeight = 50;
  num rfrac = 30;

  int nCities = 50;
  num openCost = 1000;
  Function distanceFcn = (d) => (d);

  Random rng = new Random();

  List<int> chosenCities;
  List<List<int>> assignedCities;

  Optimizer opt;

  FacilityLocation(String containerId) {
    Element vc = querySelector('#${containerId}');

    canvas = new CanvasElement();
    vc.append(canvas);
    canvas.style.width = "100%";
    canvas.width = canvas.client.width;
    canvas.height = (canvas.width / 2).toInt();
    canvas.style.border = "1px solid black";
    ctx = canvas.context2D;

    Element div = new DivElement();

    startButton = new ButtonElement();
    startButton.text = "Start";
    div.append(startButton);

    cancelButton = new ButtonElement();
    cancelButton.disabled = true;
    cancelButton.text = "Stop";
    div.append(cancelButton);

    resetButton = new ButtonElement();
    resetButton.text = "New map";
    div.append(resetButton);

    facilityCostInput = new InputElement();
    facilityCostInput.value = '1000';
    Element facilityCostWrapper = new DivElement();
    facilityCostWrapper.appendText('Facility open cost:');
    facilityCostWrapper.append(facilityCostInput);
    div.append(facilityCostWrapper);

    popSizeInput = new InputElement();
    popSizeInput.value = '100';
    Element popSizeWrapper = new DivElement();
    popSizeWrapper.appendText('Population size:');
    popSizeWrapper.append(popSizeInput);
    div.append(popSizeWrapper);

    xoverProbInput = new InputElement();
    xoverProbInput.value = '0.8';
    Element xoverProbWrapper = new DivElement();
    xoverProbWrapper.appendText('Crossover prob.:');
    xoverProbWrapper.append(xoverProbInput);
    div.append(xoverProbWrapper);

    mutProbInput = new InputElement();
    mutProbInput.value = '0.05';
    Element mutProbWrapper = new DivElement();
    mutProbWrapper.appendText('Mutation prob.:');
    mutProbWrapper.append(mutProbInput);
    div.append(mutProbWrapper);

    tournamentSizeInput = new InputElement();
    tournamentSizeInput.value = '2';
    Element tournamentSizeWrapper = new DivElement();
    tournamentSizeWrapper.appendText('Tournament size:');
    tournamentSizeWrapper.append(tournamentSizeInput);
    div.append(tournamentSizeWrapper);

    /*
    elitismInput = new InputElement();
    elitismInput.value = '4';
    */

    genDiv = new DivElement();
    div.append(genDiv);

    fitDiv = new DivElement();
    div.append(fitDiv);

    vc.append(div);

    startButton.onClick.listen((_) => start());
    cancelButton.onClick.listen((_) => cancel());
    resetButton.onClick.listen((_) => reset());
    reset();
  }

  void start() {
    print("Starting");
    if (cities == null) {
      print('Not initialized, initializing.');
      reset();
    }
    Map<String, num> values = validate();
    if (values == null) {
      return;
    }
    openCost = values['openCost'];
    opt = new Optimizer(nCities, values['popSize'], values['xoverProb'], values['mutProb'], values['tournamentSize'], 2);
    startButton.disabled = true;
    cancelButton.disabled = false;
    resetButton.disabled = true;
    run();
  }

  Map<String, num> validate() {
    bool ok = true;
    Map<String, num> params = new Map();

    num value = num.parse(facilityCostInput.value, (_) => null);
    if (value == null) {
      facilityCostInput.style.color = 'red';
      ok = false;
    } else {
      facilityCostInput.style.color = 'black';
      params['openCost'] = value;
    }

    value = int.parse(popSizeInput.value, onError: (_) => null);
    if (value == null || value < 2 || value % 2 != 0) {
      popSizeInput.style.color = 'red';
      ok = false;
    } else {
      popSizeInput.style.color = 'black';
      params['popSize'] = value;
    }

    value = double.parse(xoverProbInput.value, (_) => null);
    if (value == null || value < 0 || value > 1) {
      xoverProbInput.style.color = 'red';
      ok = false;
    } else {
      xoverProbInput.style.color = 'black';
      params['xoverProb'] = value;
    }

    value = double.parse(mutProbInput.value, (_) => null);
    if (value == null || value < 0 || value > 1) {
      mutProbInput.style.color = 'red';
      ok = false;
    } else {
      mutProbInput.style.color = 'black';
      params['mutProb'] = value;
    }

    value = int.parse(tournamentSizeInput.value, onError: (_) => null);
    if (value == null || value < 2 || (params.containsKey('popSize') && value > params['popSize'])) {
      tournamentSizeInput.style.color = 'red';
      ok = false;
    } else {
      tournamentSizeInput.style.color = 'black';
      params['tournamentSize'] = value;
    }

    return ok ? params : null;
  }

  void cancel() {
    print('Cancelling...');
    opt.cancel();
  }

  void finished() {
    print("Finished");
    startButton.disabled = false;
    cancelButton.disabled = true;
    resetButton.disabled = false;
  }

  void run() {
    opt.run();
  }

  double evaluateIndividual(Individual ind) {
    if (ind.fitness != null) {
      return ind.fitness;
    }
    List<bool> s = ind.genotype;
    num cost = 0;
    List<int> opened = [];
    List<int> served = [];
    List<List<int>> partitioning = [];
    for (int i = 0; i < s.length; i++) {
      if (s[i]) {
        cost += openCost;
        opened.add(i);
        partitioning.add([]);
      } else {
        served.add(i);
      }
    }
    if (opened.length == 0) {
      return double.INFINITY;
    }

    for (int i = 0; i < served.length; i++) {
      num d = double.INFINITY;
      int fIdx;
      City a = cities[served[i]];
      for (int j = 0; j < opened.length; j++) {
        City b = cities[opened[j]];
        num dx = a.x - b.x;
        num dy = a.y - b.y;
        num _d = distanceFcn(sqrt(dx * dx + dy * dy));
        if (_d < d) {
          fIdx = j;
          d = _d;
        }
      }
      partitioning[fIdx].add(served[i]);
      cost += d;
    }

    if (opt.bestFitness == null || cost < opt.bestFitness) {
      opt.bestFitness = cost;
      chosenCities = opened;
      assignedCities = partitioning;
      print('New best solution. Generation: ${opt.generation} Fitness: ${opt.bestFitness}');
      //render();
    }

    return cost;
  }

  void reset() {
    print("Resetting");
    generateMap();
    chosenCities = [];
    assignedCities = [];
    render();
  }

  void render() {
    if (opt == null) {
      genDiv.text = 'Generation: -';
      fitDiv.text = 'Best fitness: -';
    } else {
      genDiv.text = 'Generation: ${opt.generation}';
      fitDiv.text = 'Best fitness: ${opt.bestFitness} (${chosenCities.length} facilities)';
    }

    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    ctx.strokeStyle = '#000000';
    for (int i = 0; i < chosenCities.length; i++) {
      City c = cities[chosenCities[i]];

      for (int j = 0; j < assignedCities[i].length; j++) {
        City a = cities[assignedCities[i][j]];
        ctx.beginPath();
        ctx.moveTo(x(c.x), y(c.y));
        ctx.lineTo(x(a.x), y(a.y));
        ctx.stroke();
      }
      drawCity(c, '#ff0000', '#00ff00');
    }

    for (var i = 0; i < cities.length; i++) {
      var c = cities[i];
      drawCity(c, '#0000ff', '#00ff00');
    }

    for (var i = 0; i < chosenCities.length; i++) {
      var c = cities[chosenCities[i]];
      drawCity(c, '#ff0000', '#00ff00');
    }
  }

  void drawCity(City c, String cs, String ts) {
    ctx.fillStyle = cs;
    ctx.beginPath();
    ctx.arc(x(c.x), y(c.y), r(), 0, 2 * PI);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = ts;
    ctx.fillText('' + c.id.toString(), x(c.x), y(c.y));
  }

  num r() {
    return ctx.canvas.height / rfrac;
  }

  num x(num _x) {
    num _r = r();
    return _x * (ctx.canvas.width - 2 * _r) / modelWidth + _r;
  }

  num y(num _y) {
    var _r = r();
    return _y * (ctx.canvas.height - 2 * _r) / modelHeight + _r;
  }

  void generateMap() {
    cities = [];

    bool isNear(c) {
      for (int i = 0; i < cities.length; i++) {
        num dx = x(c.x) - x(cities[i].x);
        num dy = y(c.y) - y(cities[i].y);
        num _r = r();
        num d = sqrt(dx * dx + dy * dy);
        if (d <= 3 * _r) {
          return true;
        }
      }
      return false;
    }

    for (int i = 0; i < nCities; i++) {
      City c = new City(null, null, i);
      int tries = 0;
      bool near = true;
      do {
        if (tries > 100) {
          generateMap();
          return;
        }
        c.x = rng.nextDouble() * modelWidth;
        c.y = rng.nextDouble() * modelHeight;
        near = isNear(c);
        tries++;
      } while (near);
      cities.add(c);
    }
  }
}

class Optimizer {
  static final Duration delay = new Duration(milliseconds: 500);

  List<Individual> population;

  double xoverProb = 0.8;
  double mutProb = 0.1;
  int tournamentSize = 2;
  int elitism = 4;

  Random rng = new Random();

  int popSize = 500;
  int genotypeLength;

  int generation;
  num bestFitness;

  bool cancelled;

  Optimizer(this.genotypeLength, this.popSize, this.xoverProb, this.mutProb, this.tournamentSize, this.elitism) {
    this.generation = 0;
    this.bestFitness = null;
    this.cancelled = false;
  }

  void run() {
    initPop();
    generation = 0;
    cancelled = false;
    new Future.delayed(delay, () => doGeneration());
  }

  void cancel() {
    cancelled = true;
    print('Cancelled: ${cancelled}');
  }

  void doGeneration() {
    print('Generation ${generation}');
    List<Individual> newPop = [];
    while (newPop.length < popSize) {
      Individual p1 = select();
      Individual p2 = select();
      p1 = p1.clone();
      p2 = p2.clone();
      xover(p1, p2);
      mutate(p1);
      mutate(p2);
      newPop.addAll([p1, p2]);
    }
    population = newPop;
    generation++;
    facilityLocation.render();
    if (!cancelled) {
      new Future.delayed(delay, () => doGeneration());
    } else {
      facilityLocation.finished();
    }
  }

  void initPop() {
    population = new List(popSize);
    for (int i = 0; i < popSize; i++) {
      List<bool> genotype = new List(genotypeLength);
      for (int j = 0; j < genotype.length; j++) {
        genotype[j] = rng.nextBool();
      }
      population[i] = new Individual(genotype, null);
    }
  }

  Individual select() {
    Individual winner = null;
    for (int i = 0; i < tournamentSize; i++) {
      Individual candidate = population[rng.nextInt(popSize)];
      if (winner == null) {
        winner = candidate;
        continue;
      }
      if (compare(candidate, winner)) {
        winner = candidate;
      }
    }
    return winner;
  }

  bool compare(Individual a, Individual b) {
    if (a.fitness == null) {
      evaluate(a);
    }
    if (b.fitness == null) {
      evaluate(b);
    }

    return a.fitness < b.fitness;
  }

  void evaluate(Individual i) {
    num f = facilityLocation.evaluateIndividual(i);
    i.fitness = f;
  }

  void xover(Individual a, Individual b) {
    if (rng.nextDouble() >= xoverProb) {
      return;
    }
    int point = rng.nextInt(genotypeLength);
    List<bool> ag = a.genotype.sublist(0, point);
    ag.addAll(b.genotype.sublist(point));
    List<bool> bg = b.genotype.sublist(0, point);
    bg.addAll(a.genotype.sublist(point));
    a.genotype = ag;
    a.fitness = null;
    b.genotype = bg;
    b.fitness = null;
  }

  void mutate(Individual i) {
    for (int n = 0; n < genotypeLength; n++) {
      if (rng.nextDouble() < mutProb) {
        i.genotype[n] = !i.genotype[n];
      }
    }
  }
}