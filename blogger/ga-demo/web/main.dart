// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:math';
import 'dart:io';
import 'dart:async';

VertexCover vertexCover;

void main() {
  Element vc = querySelector('#vertex-cover');

  CanvasElement canvas = new CanvasElement();
  vc.append(canvas);
  canvas.style.width = "100%";
  canvas.width = canvas.client.width;
  canvas.height = (canvas.width / 2).toInt();
  canvas.style.border = "1px solid black";

  Element div = new DivElement();
  Element startButton = new ButtonElement();
  startButton.text = "Start";
  Element resetButton = new ButtonElement();
  resetButton.text = "Reset";
  Element genDiv = new DivElement();
  Element fitDiv = new DivElement();
  div.append(startButton);
  div.append(resetButton);
  div.append(genDiv);
  div.append(fitDiv);
  vc.append(div);

  vertexCover = new VertexCover(canvas, startButton, resetButton, genDiv, fitDiv);

  startButton.onClick.listen((_) => vertexCover.start());
  resetButton.onClick.listen((_) => vertexCover.reset());
}

class VertexCover {
  CanvasElement canvas;
  ButtonElement startButton;
  ButtonElement resetButton;
  DivElement genDiv;
  DivElement fitDiv;
  List<Set<int>> adjlist;
  int totalEdges;
  Set<int> coveredVertices;
  Random rng = new Random();

  int generation = 0;
  Fitness fitness;
  bool feasible;

  static final int COLS = 20;
  static final int ROWS = 10;
  static final double EDGE_PROB = 0.5;

  VertexCover(this.canvas, this.startButton, this.resetButton, this.genDiv, this.fitDiv);

  void start() {
    print("Starting");
    startButton.disabled = true;
    resetButton.disabled = true;
    run();
    startButton.disabled = false;
    resetButton.disabled = false;
  }

  void run() {
    new Future(() {
      Optimizer opt = new Optimizer(COLS * ROWS);
      opt.run();
    });
  }

  Fitness evaluateIndividual(List<bool> coveredNodes) {
    int coveredEdges = 0;
    int usedNodes = 0;
    Set<int> closedNodes = new Set();
    for (int n = 0; n < coveredNodes.length; n++) {
      if (coveredNodes[n]) {
        usedNodes++;
        for (int nn in adjlist[n]) {
          if (!closedNodes.contains(nn)) {
            coveredEdges++;
          }
        }
        closedNodes.add(n);
      }
    }
    return new Fitness(coveredEdges, usedNodes);
  }

  void setSolution(Individual ind, int generation) {
    coveredVertices.clear();
    for (int i = 0; i < ind.genotype.length; i++) {
      if (ind.genotype[i]) {
        coveredVertices.add(i);
      }
    }
    feasible = ind.fitness.coveredEdges == totalEdges;
    fitness = ind.fitness;
    scheduleMicrotask(() {
      render();
    });
  }

  void reset() {
    print("Resetting");
    _generateGraph();
    coveredVertices = new Set();
    render();
  }

  void render() {
    if (fitness != null) {
      fitDiv.text = "Best fitness: ${fitness.coveredEdges} covered edges${feasible ? "" : " (infeasible)"}, ${fitness.usedNodes}";
    }
    genDiv.text = "Generation: ${generation}";

    double ox = 20.0;
    double oy = 20.0;
    double w = canvas.client.width - ox * 2.0;
    double h = canvas.client.height - oy * 2.0;
    double dx = w / (COLS - 1);
    double dy = h / (ROWS - 1);
    double r = min(min(dx / 4, dy / 4), ox / 2.5);
    CanvasRenderingContext2D ctx = canvas.context2D;
    ctx.clearRect(0, 0, canvas.client.width, canvas.client.height);

    ctx..lineWidth = 1
       ..fillStyle = "#ff0000"
       ..strokeStyle = "#ff0000";
    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        double cx = ox + x * dx;
        double cy = oy + y * dy;
        ctx..beginPath()
           ..arc(cx, cy, r, 0, PI * 2, false)
           ..fill()
           ..closePath();

        int i = _c2i(x, y);
        for (int j in adjlist[i]) {
          if (j > i) {
            continue;
          }
          int x2 = _i2x(j);
          int y2 = _i2y(j);
          double cx2 = ox + x2 * dx;
          double cy2 = oy + y2 * dy;
          ctx..moveTo(cx, cy)
            ..lineTo(cx2, cy2)
            ..stroke();
        }
      }
    }
    ctx..lineWidth = 2
      ..fillStyle = "#000000"
      ..strokeStyle = "#000000";
    for (int i in coveredVertices) {
      int x = _i2x(i);
      int y = _i2y(i);
      double cx = ox + x * dx;
      double cy = oy + y * dy;
      ctx..beginPath()
        ..arc(cx, cy, r, 0, PI * 2, false)
        ..fill()
        ..closePath();

      for (int j in adjlist[i]) {
        int x2 = _i2x(j);
        int y2 = _i2y(j);
        double cx2 = ox + x2 * dx;
        double cy2 = oy + y2 * dy;
        ctx..moveTo(cx, cy)
           ..lineTo(cx2, cy2)
           ..stroke();
      }
    }
  }

  void _generateGraph() {
    print('Generating graph.');
    adjlist = new List();
    for (int i = 0; i < ROWS * COLS; i++) {
      adjlist.add(new Set());
    }

    for (int x = 0; x < COLS; x++) {
      for (int y = 0; y < ROWS; y++) {
        int ia = _c2i(x, y);
        List<int> ibs = [];
        if (x - 1 >= 0) {
          int ib = _c2i(x - 1, y);
          ibs.add(ib);
        }
        if (y - 1 >= 0) {
          int ib = _c2i(x, y - 1);
          ibs.add(ib);
        }
        if (x + 1 < COLS) {
          int ib = _c2i(x + 1, y);
          ibs.add(ib);
        }
        if (y + 1 < ROWS) {
          int ib = _c2i(x, y + 1);
          ibs.add(ib);
        }
        for (int ib in ibs) {
          if (rng.nextDouble() < 1 - 0.5 * sqrt(4 - 4 * EDGE_PROB)) {
            adjlist[ia].add(ib);
            adjlist[ib].add(ia);
          }
        }
      }
    }
    for (int i = 0; i < adjlist.length; i++) {
      print('${i}: ${adjlist[i]}');
    }
    totalEdges = 0;
    for (Set<int> n in adjlist) {
      totalEdges += n.length;
    }
    totalEdges = totalEdges ~/ 2;
    print('Total edges: ${totalEdges}');
    print('Graph generated.');
  }

  int _c2i(int x, int y) {
    return y * COLS + x;
  }

  int _i2x(int i) {
    return i % COLS;
  }

  int _i2y(int i) {
    return i ~/ COLS;
  }
}

class Individual {
  List<bool> genotype;
  Fitness fitness = null;

  Individual(this.genotype);
  Individual.from(Individual other) {
    this.genotype = new List.from(other.genotype);
    this.fitness = new Fitness(other.fitness.coveredEdges, other.fitness.usedNodes);
  }

  String toString() {
    return "f = ${fitness} ${genotype.map((b) => b ? '1' : '0').join()}";
  }

  Individual clone() {
    return new Individual.from(this);
  }
}

class Fitness {
  int usedNodes;
  int coveredEdges;

  Fitness(this.coveredEdges, this.usedNodes);

  static compare(Fitness a, Fitness b) {
    if (a.coveredEdges < b.coveredEdges) {
      return false;
    } else if (a.coveredEdges > b.coveredEdges) {
      return true;
    }
    return a.usedNodes < b.usedNodes;
  }

  String toString() {
    return "Covered edges: ${coveredEdges} Used nodes: ${usedNodes}";
  }


}

class Optimizer {
  List<Individual> population;
  Individual bsf;

  double xoverProb = 0.8;
  double mutProb = 0.1;
  int tournamentSize = 2;
  int elitism = 4;

  Random rng = new Random();

  int generations = 1000;
  int popSize = 500;
  int genotypeLength;

  int generation;

  Optimizer(this.genotypeLength);

  void run() {
    initPop();
    for (generation = 0; generation < generations; generation++) {
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
    }
  }

  void initPop() {
    population = new List(popSize);
    for (int i = 0; i < popSize; i++) {
      List<bool> genotype = new List(genotypeLength);
      for (int j = 0; j < genotype.length; j++) {
        genotype[j] = rng.nextBool();
      }
      population[i] = new Individual(genotype);
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

    return Fitness.compare(a.fitness, b.fitness);
  }

  void evaluate(Individual i) {
    i.fitness = vertexCover.evaluateIndividual(i.genotype);
    checkBsf(i);
  }

  void checkBsf(Individual i) {
    if (bsf == null || compare(i, bsf)) {
      print('New bsf: ${bsf}');
      bsf = i;
      vertexCover.setSolution(bsf, generation);
    }
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