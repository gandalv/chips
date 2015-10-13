// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'dart:js';
import 'dart:core';
import 'package:math_jax_wrapper/math_jax_wrapper.dart';

Problem p;
void main() {
  mathJaxInit();

  p = new Problem('problem');
}

void setVars(Node root, num x) {
  root.fold((Node node) {
    if (node is Variable) {
      (node as Variable).setValue(x);
    }
  });
}

typedef Node NodeCreator();

abstract class Node {
  Node parent;
  List<Node> children;
  int parentIndex;
  int treeSize;

  Node() {
    this.parent = null;
    this.children = [];
    this.parentIndex = null;
  }

  num eval();

  int getArity();

  String toTex();

  Node clone();

  bool isRoot() {
    return parent == null;
  }

  Node getParent() {
    if (parent == null) {
      return this;
    }
    return parent.getParent();
  }

  void fold(void func(Node)) {
    func(this);
    for (Node child in this.children) {
      child.fold(func);
    }
  }

  int getTreeSize() {
    if (children.isEmpty) {
      treeSize = 1;
    } else {
      treeSize = 1 + children.map((Node n) => n.getTreeSize()).reduce((int a, int b) => a + b);
    }
    return treeSize;
  }

  Node getNthNode(int n) {
    getTreeSize();
    return _getNthNode(n);
  }

  Node _getNthNode(int n) {
    n = n % treeSize;
    //print('Requesting ${n}-th node of ${this}');
    if (n == 0) {
      //print('Found.');
      return this;
    }
    n -= 1;
    for (Node node in children) {
      if (n < node.treeSize) {
        return node._getNthNode(n);
      }
      n -= node.treeSize;
    }
    throw new StateError('Unreachable code.');
  }
}

class Variable extends Node {
  String name;
  num value;

  Variable(this.name) {}

  void setValue(num value) {
    this.value = value;
  }

  @override
  num eval() {
    return this.value;
  }

  @override
  int getArity() {
    return 0;
  }

  @override
  String toTex() {
    return name;
  }

  @override
  Node clone() {
    Variable c = new Variable(this.name);
    c.value = this.value;
    return c;
  }

  String toString() {
   return name;
  }
}

class Constant extends Node {
  num value;

  Constant(this.value) {}

  @override
  num eval() {
    return this.value;
  }

  @override
  int getArity() {
    return 0;
  }

  @override
  String toTex() {
    return '${value}';
  }

  @override
  Node clone() {
    Constant c = new Constant(this.value);
    return c;
  }

  String toString() {
    return '${value}';
  }
}

class PlusNode extends Node {

  @override
  num eval() {
    return this.children[0].eval() + this.children[1].eval();
  }

  @override
  int getArity() {
    return 2;
  }

  @override
  String toTex() {
    return '\\left(${this.children[0].toTex()} + ${this.children[1].toTex()}\\right)';
  }

  @override
  Node clone() {
    PlusNode c = new PlusNode();
    Node c0 = this.children[0].clone();
    Node c1 = this.children[1].clone();
    c0.parent = c;
    c0.parentIndex = 0;
    c1.parent = c;
    c1.parentIndex = 1;
    c.children.add(c0);
    c.children.add(c1);
    return c;
  }

  String toString() {
    return '(+ ${children[0].toString()} ${children[1].toString()})';
  }
}

class MinusNode extends Node {

  @override
  num eval() {
    return this.children[0].eval() - this.children[1].eval();
  }

  @override
  int getArity() {
    return 2;
  }

  @override
  String toTex() {
    return '\\left(${this.children[0].toTex()} - ${this.children[1].toTex()}\\right)';
  }

  @override
  Node clone() {
    MinusNode c = new MinusNode();
    Node c0 = this.children[0].clone();
    Node c1 = this.children[1].clone();
    c0.parent = c;
    c0.parentIndex = 0;
    c1.parent = c;
    c1.parentIndex = 1;
    c.children.add(c0);
    c.children.add(c1);
    return c;
  }

  String toString() {
    return '(- ${children[0].toString()} ${children[1].toString()})';
  }
}

class TimesNode extends Node {

  @override
  num eval() {
    return this.children[0].eval() * this.children[1].eval();
  }

  @override
  int getArity() {
    return 2;
  }

  @override
  String toTex() {
    return '\\left(${this.children[0].toTex()} \\cdot ${this.children[1].toTex()}\\right)';
  }

  @override
  Node clone() {
    TimesNode c = new TimesNode();
    Node c0 = this.children[0].clone();
    Node c1 = this.children[1].clone();
    c0.parent = c;
    c0.parentIndex = 0;
    c1.parent = c;
    c1.parentIndex = 1;
    c.children.add(c0);
    c.children.add(c1);
    return c;
  }

  String toString() {
    return '(* ${children[0].toString()} ${children[1].toString()})';
  }
}

class DivideNode extends Node {

  @override
  num eval() {
    return this.children[0].eval() / this.children[1].eval();
  }

  @override
  int getArity() {
    return 2;
  }

  @override
  String toTex() {
    return '\\frac{' + this.children[0].toTex() + '}{' + this.children[1].toTex() + '}';
  }

  @override
  Node clone() {
    DivideNode c = new DivideNode();
    Node c0 = this.children[0].clone();
    Node c1 = this.children[1].clone();
    c0.parent = c;
    c0.parentIndex = 0;
    c1.parent = c;
    c1.parentIndex = 1;
    c.children.add(c0);
    c.children.add(c1);
    return c;
  }

  String toString() {
    return '(/ ${children[0].toString()} ${children[1].toString()})';
  }
}

class LnNode extends Node {

  @override
  num eval() {
    return log(this.children[0].eval());
  }

  @override
  int getArity() {
    return 1;
  }

  @override
  String toTex() {
    return '\\ln\\left(' + this.children[0].toTex() + '\\right)';
  }

  @override
  Node clone() {
    LnNode c = new LnNode();
    Node c0 = this.children[0].clone();
    c0.parent = c;
    c0.parentIndex = 0;
    c.children.add(c0);
    return c;
  }

  String toString() {
    return '(ln ${children[0].toString()})';
  }
}

class ExpNode extends Node {

  @override
  num eval() {
    return exp(this.children[0].eval());
  }

  @override
  int getArity() {
    return 1;
  }

  @override
  String toTex() {
    return '\\mathrm{e}^{' + this.children[0].toTex() + '}';
  }

  @override
  Node clone() {
    ExpNode c = new ExpNode();
    Node c0 = this.children[0].clone();
    c0.parent = c;
    c0.parentIndex = 0;
    c.children.add(c0);
    return c;
  }

  String toString() {
    return '(exp ${children[0].toString()})';
  }
}

class SinNode extends Node {

  @override
  num eval() {
    return sin(this.children[0].eval());
  }

  @override
  int getArity() {
    return 1;
  }

  @override
  String toTex() {
    return '\\sin\\left(' + this.children[0].toTex() + '\\right)';
  }

  @override
  Node clone() {
    SinNode c = new SinNode();
    Node c0 = this.children[0].clone();
    c0.parent = c;
    c0.parentIndex = 0;
    c.children.add(c0);
    return c;
  }

  String toString() {
    return '(sin ${children[0].toString()})';
  }
}

class CosNode extends Node {

  @override
  num eval() {
    return cos(this.children[0].eval());
  }

  @override
  int getArity() {
    return 1;
  }

  @override
  String toTex() {
    return '\\cos\\left(' + this.children[0].toTex() + '\\right)';
  }

  @override
  Node clone() {
    CosNode c = new CosNode();
    Node c0 = this.children[0].clone();
    c0.parent = c;
    c0.parentIndex = 0;
    c.children.add(c0);
    return c;
  }

  String toString() {
    return '(cos ${children[0].toString()})';
  }
}

class Individual {
  Node root;
  num fitness;

  Individual(this.root, this.fitness) {}

  String toString() {
    return '${fitness}: ${root}';
  }

  Individual clone() {
    return new Individual(root.clone(), fitness);
  }
}

class Optimizer {
  static final Duration delay = new Duration(milliseconds: 1000);

  Problem problem;

  List<NodeCreator> nterms;
  List<NodeCreator> terms;

  List<Individual> population;

  int popSize;
  double xoverProb;
  double mutProb;
  int tournamentSize;
  int elitism;

  int minInitDepth = 1;
  int maxInitDepth = 5;
  int mutDepth = 4;

  Random rng = new Random();


  int generation;
  num bestFitness;
  int bestFitnessGen;

  bool cancelled;

  Optimizer(this.problem, this.popSize, this.xoverProb, this.mutProb, this.tournamentSize, this.elitism) {
    this.generation = 0;
    this.bestFitness = null;
    this.cancelled = false;

    this.nterms = [
          () => new PlusNode(),
          () => new MinusNode(),
          () => new TimesNode(),
          () => new DivideNode(),
          () => new ExpNode(),
          () => new LnNode(),
          () => new SinNode(),
          () => new CosNode()
    ];
    this.terms = [
          () => new Variable('x'),
          () => new Constant(1.0),
          () => new Constant(-1.0),
          () => new Constant(10.0),
          () => new Constant(-10.0)
    ];
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
    print('${new DateTime.now()} Generation ${generation}.');
    List<Individual> newPop = extractElites();
    while (newPop.length < popSize) {
      Individual p1 = select();
      Individual p2 = select();
      p1 = p1.clone();
      p2 = p2.clone();
      xover(p1, p2);
      mutate(p1);
      mutate(p2);
      newPop.add(p1);
      newPop.add(p2);
    }
    population = newPop;
    problem.render();
    if (!cancelled) {
      new Future.delayed(delay, () => doGeneration());
    } else {
      problem.finished();
    }
    print('${new DateTime.now()} Generation ${generation} finished.');
    generation++;
  }

  void initPop() {
    population = new List.filled(popSize, null);
    int levels = maxInitDepth - minInitDepth;
    int groupSize = (popSize / (2 * levels)).floor();
    int rem = popSize - 2 * levels * groupSize;
    int i = 0;
    for (int l = 0; l < levels; l++) {
      for (int n = 0; n < groupSize + (rem > 0 ? 1 : 0); n++) {
        Node r = generateGrow(minInitDepth + l);
        population[i++] = new Individual(r, null);
      }
      rem--;

      for (int n = 0; n < groupSize + (rem > 0 ? 1 : 0); n++) {
        Node r = generateFull(minInitDepth + l);
        population[i++] = new Individual(r, null);
      }
      rem--;
    }
  }

  Individual select() {
    //print('Selecting');
    Individual winner = null;
    for (int i = 0; i < tournamentSize; i++) {
      Individual candidate = population[rng.nextInt(popSize)];
      if (winner == null) {
        winner = candidate;
        continue;
      }
      if (compare(candidate, winner) < 0) {
        winner = candidate;
      }
    }
    return winner;
  }

  List<Individual> extractElites() {
    if (elitism == 0) {
      return [];
    }

    List<Individual> elites = [];
    for (Individual i in population) {
      if (elites.isEmpty) {
        elites.add(i);
        continue;
      }

      for (int e = 0; e < elites.length; e++) {
        if (compare(i, elites[e]) <= 0) {
          elites.insert(e, i);
          break;
        }
      }
      if (elites.length > elitism) {
        elites.removeLast();
      }
    }

    return elites;
  }

  int compare(Individual a, Individual b) {
    if (a.fitness == null) {
      evaluate(a);
    }
    if (b.fitness == null) {
      evaluate(b);
    }

    if (a.fitness < b.fitness) {
      return -1;
    }
    if (a.fitness > b.fitness) {
      return 1;
    }
    return 0;
  }

  void evaluate(Individual i) {
    num f = problem.evaluateIndividual(i);
    i.fitness = f;
  }

  void xover(Individual a, Individual b) {
    if (rng.nextDouble() >= xoverProb) {
      return;
    }
    //print('Xovering ${a.root} and ${b.root}');
    int ats = a.root.getTreeSize();
    //print('  A tree size: ${ats}');
    int apt = rng.nextInt(ats);
    //print('  A point: ${apt}');
    int bts = b.root.getTreeSize();
    //print('  B tree size: ${bts}');
    int bpt = rng.nextInt(bts);
    //print('  B point: ${bpt}');

    Node pointA = a.root._getNthNode(apt);
    //print('  A subtree: ${pointA}');

    Node pointB = b.root._getNthNode(bpt);
    //print('  B subtree: ${pointB}');

    _swapSubtrees(a, pointA, b, pointB);
  }

  void _swapSubtrees(Individual a, Node pointA, Individual b, Node pointB) {
    if (pointA.isRoot() && pointB.isRoot()) {
      a.root = pointB;
      b.root = pointA;

      int tmp = b.fitness;
      a.fitness = b.fitness;
      b.fitness = tmp;
    } else if (pointA.isRoot() && !pointB.isRoot()) {
      b.root = pointA.clone();
      b.root.parent = null;
      b.root.parentIndex = null;
      b.fitness = a.fitness;

      Node bP = pointB.parent;
      int bPI = pointB.parentIndex;

      bP.children[bPI] = pointA;
      pointA.parent = bP;
      pointA.parentIndex = bPI;

      a.fitness = null;
    } else if (!pointA.isRoot() && pointB.isRoot()) {
      a.root = pointB.clone();
      a.root.parent = null;
      a.root.parentIndex = null;
      a.fitness = b.fitness;

      Node aP = pointA.parent;
      int aPI = pointA.parentIndex;

      aP.children[aPI] = pointB;
      pointB.parent = aP;
      pointB.parentIndex = aPI;

      a.fitness = null;
    } else {
      Node aP = pointA.parent;
      Node bP = pointB.parent;
      int aPI = pointA.parentIndex;
      int bPI = pointB.parentIndex;

      aP.children[aPI] = pointB;
      bP.children[bPI] = pointA;

      pointA.parent = bP;
      pointB.parent = aP;

      pointA.parentIndex = bPI;
      pointB.parentIndex = aPI;

      a.fitness = null;
      b.fitness = null;
    }
  }

  void mutate(Individual i) {
    if (rng.nextDouble() >= mutProb) {
      return;
    }
    //print('Mutating ${i.root}');
    Node p = i.root.getNthNode(rng.nextInt(i.root.getTreeSize()));
    Node n = generateGrow(mutDepth);

    if (p.isRoot()) {
      i.root = p;
    } else {
      n.parent = p.parent;
      n.parentIndex = p.parentIndex;
      n.parent.children[n.parentIndex] = n;
    }
    i.fitness = null;
  }

  Node generate(List<NodeCreator> nonterminals, List<NodeCreator> terminals, int maxDepth) {
    if (maxDepth <= 0) {
      return terminals[rng.nextInt(terminals.length)]();
    }

    Node n = nonterminals[rng.nextInt(nonterminals.length)]();
    n.children = new List<Node>.filled(n.getArity(), null);
    for (int i = 0; i < n.getArity(); i++) {
      Node c = generate(nonterminals, terminals, maxDepth - 1);
      c.parent = n;
      c.parentIndex = i;
      n.children[i] = c;
    }
    return n;
  }

  Node generateFull(int maxDepth) {
    return generate(
        nterms,
        terms,
        maxDepth
    );
  }

  Node generateGrow(int maxDepth) {
    return generate(
        new List.from(nterms)..addAll(terms),
        terms,
        maxDepth
    );
  }
}

class Problem {
  ButtonElement startButton;
  ButtonElement cancelButton;
  InputElement popSizeInput;
  InputElement xoverProbInput;
  InputElement mutProbInput;
  InputElement tournamentSizeInput;
  InputElement elitesNumInput;
  InputElement samplePointsNumInput;
  DivElement genDiv;
  DivElement fitDiv;
  DivElement texDiv;

  JsObject board;
  List<JsObject> samplePointsRender;
  JsObject fgraph;
  bool wasRendered = false;

  var trueFunction = (num x) => 5 * sin(x*x);
  num lb = -5;
  num ub = 5;
  int samplePointsNum = 20;
  List<Point<double>> samplePoints;

  Node bsf;
  Optimizer opt;

  Problem(String containerId) {
    Element container = querySelector('#${containerId}');
    container.style.width = '100%';
    // container.style.height = '${container.clientWidth}px';
    container.className = 'center-block';

    DivElement outputContainer = new DivElement();
    container.append(outputContainer);
    outputContainer.style.float = 'left';
    outputContainer.style.width = '70%';

    DivElement plot = new DivElement();
    outputContainer.append(plot);
    plot.style.width = '100%';
    plot.style.height = '${plot.clientWidth * 0.5}px';
    plot.id = 'plotBox';
    plot.className = 'jxgbox';

    texDiv = new DivElement();
    outputContainer.append(texDiv);
    texDiv.style.width = '100%';
    texDiv.id = 'texDisp';

    genDiv = new DivElement();
    outputContainer.append(genDiv);
    genDiv.id = 'genDisp';

    fitDiv = new DivElement();
    outputContainer.append(fitDiv);
    fitDiv.id = 'fitDisp';

    DivElement controls = new DivElement();
    container.append(controls);
    //controls.style.float = 'right';
    //controls.style.marginLeft = '${outputContainer.clientWidth - 50}px';

    DivElement popSizeControl = new DivElement();
    LabelElement popSizeLabel = new LabelElement();
    popSizeLabel.text = 'Population size: ';
    popSizeLabel.style.float = 'left';
    popSizeLabel.setAttribute('for', 'popSize');
    popSizeControl.append(popSizeLabel);
    SpanElement popSizeInputWrap = new SpanElement();
    popSizeInputWrap.style.display = 'block';
    popSizeInputWrap.style.overflow = 'hidden';
    popSizeControl.append(popSizeInputWrap);
    popSizeInput = new InputElement();
    popSizeInput.id = 'popSize';
    popSizeInput.type = 'number';
    popSizeInput.value = '1000';
    popSizeInput.style.width = '100%';
    popSizeInputWrap.append(popSizeInput);
    controls.append(popSizeControl);

    DivElement xoverProbControl = new DivElement();
    LabelElement xoverProbLabel = new LabelElement();
    xoverProbLabel.text = 'Crossover prob.: ';
    xoverProbLabel.style.float = 'left';
    xoverProbLabel.setAttribute('for', 'xoverProb');
    xoverProbControl.append(xoverProbLabel);
    SpanElement xoverProbInputWrap = new SpanElement();
    xoverProbInputWrap.style.display = 'block';
    xoverProbInputWrap.style.overflow = 'hidden';
    xoverProbControl.append(xoverProbInputWrap);
    xoverProbInput = new InputElement();
    xoverProbInput.id = 'xoverProb';
    xoverProbInput.type = 'number';
    xoverProbInput.value = '0.4';
    xoverProbInput.style.width = '100%';
    xoverProbInputWrap.append(xoverProbInput);
    controls.append(xoverProbControl);

    DivElement mutProbControl = new DivElement();
    LabelElement mutProbLabel = new LabelElement();
    mutProbLabel.text = 'Mutation prob.: ';
    mutProbLabel.style.float = 'left';
    mutProbLabel.setAttribute('for', 'mutProb');
    mutProbControl.append(mutProbLabel);
    SpanElement mutProbInputWrap = new SpanElement();
    mutProbInputWrap.style.display = 'block';
    mutProbInputWrap.style.overflow = 'hidden';
    mutProbControl.append(mutProbInputWrap);
    mutProbInput = new InputElement();
    mutProbInput.id = 'mutProb';
    mutProbInput.type = 'number';
    mutProbInput.value = '0.5';
    mutProbInput.style.width = '100%';
    mutProbInputWrap.append(mutProbInput);
    controls.append(mutProbControl);

    DivElement tournamentSizeControl = new DivElement();
    LabelElement tournamentSizeLabel = new LabelElement();
    tournamentSizeLabel.text = 'Tournament size: ';
    tournamentSizeLabel.style.float = 'left';
    tournamentSizeLabel.setAttribute('for', 'tournamentSize');
    tournamentSizeControl.append(tournamentSizeLabel);
    SpanElement tournamentSizeInputWrap = new SpanElement();
    tournamentSizeInputWrap.style.display = 'block';
    tournamentSizeInputWrap.style.overflow = 'hidden';
    tournamentSizeControl.append(tournamentSizeInputWrap);
    tournamentSizeInput = new InputElement();
    tournamentSizeInput.id = 'tournamentSize';
    tournamentSizeInput.type = 'number';
    tournamentSizeInput.value = '4';
    tournamentSizeInput.style.width = '100%';
    tournamentSizeInputWrap.append(tournamentSizeInput);
    controls.append(tournamentSizeControl);

    DivElement elitesNumControl = new DivElement();
    LabelElement elitesNumLabel = new LabelElement();
    elitesNumLabel.text = 'No. of elites: ';
    elitesNumLabel.style.float = 'left';
    elitesNumLabel.setAttribute('for', 'elitesNum');
    elitesNumControl.append(elitesNumLabel);
    SpanElement elitesNumInputWrap = new SpanElement();
    elitesNumInputWrap.style.display = 'block';
    elitesNumInputWrap.style.overflow = 'hidden';
    elitesNumControl.append(elitesNumInputWrap);
    elitesNumInput = new InputElement();
    elitesNumInput.id = 'elitesNum';
    elitesNumInput.type = 'number';
    elitesNumInput.value = '10';
    elitesNumInput.style.width = '100%';
    elitesNumInputWrap.append(elitesNumInput);
    controls.append(elitesNumControl);

    DivElement samplePointsNumControl = new DivElement();
    LabelElement samplePointsNumLabel = new LabelElement();
    samplePointsNumLabel.text = 'No. of sample points: ';
    samplePointsNumLabel.style.float = 'left';
    samplePointsNumLabel.setAttribute('for', 'samplePointsNum');
    samplePointsNumControl.append(samplePointsNumLabel);
    SpanElement samplePointsNumInputWrap = new SpanElement();
    samplePointsNumInputWrap.style.display = 'block';
    samplePointsNumInputWrap.style.overflow = 'hidden';
    samplePointsNumControl.append(samplePointsNumInputWrap);
    samplePointsNumInput = new InputElement();
    samplePointsNumInput.id = 'samplePointsNum';
    samplePointsNumInput.type = 'number';
    samplePointsNumInput.value = '${samplePointsNum}';
    samplePointsNumInput.maxLength = 4;
    samplePointsNumInput.style.width = '100%';
    samplePointsNumInput.onChange.listen((_) {
      num value = int.parse(samplePointsNumInput.value, onError: (_) => null);
      if (value == null || value < 2) {
        samplePointsNumInput.style.color = 'red';
      } else {
        samplePointsNumInput.style.color = 'black';
        samplePointsNum = value;
        generateSamplePoints();
      }
    });
    samplePointsNumInputWrap.append(samplePointsNumInput);
    controls.append(samplePointsNumControl);

    startButton = new ButtonElement();
    startButton.text = 'Start';
    controls.append(startButton);

    cancelButton = new ButtonElement();
    cancelButton.text = 'Cancel';
    cancelButton.disabled = true;
    controls.append(cancelButton);

    JsObject jsxGraph = context['JXG']['JSXGraph'];
    board = jsxGraph.callMethod('initBoard', [
      'plotBox',
      new JsObject.jsify({
        'boundingbox': [-5.2, 25, 5.2, -10],
        'axis': true,
        'keepaspectratio': false,
        'showNavigation': false
      })
    ]);
    board.callMethod('create', [
      'functiongraph',
      new JsObject.jsify([(x, _) => trueFunction(x), -5, 5]),
      new JsObject.jsify({'strokeColor': '#eeeeee', 'dash': 2})
    ]);

    generateSamplePoints();

    startButton.onClick.listen((_) => start());
    cancelButton.onClick.listen((_) => cancel());
  }

  void start() {
    print('Starting');
    render();
    Map<String, num> values = validate();
    if (values == null) {
      return;
    }
    samplePointsNum = values['samplePointsNum'];
    generateSamplePoints();
    bsf = null;
    opt = new Optimizer(this, values['popSize'], values['xoverProb'], values['mutProb'], values['tournamentSize'], values['elitesNum']);
    startButton.disabled = true;
    cancelButton.disabled = false;

    popSizeInput.disabled = true;
    xoverProbInput.disabled = true;
    mutProbInput.disabled = true;
    tournamentSizeInput.disabled = true;
    elitesNumInput.disabled = true;
    samplePointsNumInput.disabled = true;

    run();
  }

  Map<String, num> validate() {
    bool ok = true;
    Map<String, num> params = new Map();

    num value = int.parse(popSizeInput.value, onError: (_) => null);
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

    value = int.parse(elitesNumInput.value, onError: (_) => null);
    if (value == null || value < 0 || value % 2 != 0 || (params.containsKey('popSize') && value > params['popSize'])) {
      elitesNumInput.style.color = 'red';
      ok = false;
    } else {
      elitesNumInput.style.color = 'black';
      params['elitesNum'] = value;
    }

    value = int.parse(samplePointsNumInput.value, onError: (_) => null);
    if (value == null || value < 2) {
      samplePointsNumInput.style.color = 'red';
      ok = false;
    } else {
      samplePointsNumInput.style.color = 'black';
      params['samplePointsNum'] = value;
    }

    return ok ? params : null;
  }

  void generateSamplePoints() {
    if (samplePointsRender != null) {
      for (JsObject pt in samplePointsRender) {
        board.callMethod('removeObject', [pt]);
      }
    }
    samplePointsRender = [];
    samplePoints = [];
    double d = (ub - lb) / (samplePointsNum - 1);

    for (int i = 0; i < samplePointsNum; i++) {
      Point<double> p = new Point(lb + i * d, trueFunction(lb + i * d));
      samplePoints.add(p);

      JsObject gp = board.callMethod('create', [
        'point',
        new JsObject.jsify([p.x, p.y]),
        new JsObject.jsify({'size': 2, 'strokeColor': 'red', 'fillColor': 'red'})
      ]);
      gp.callMethod('setName', ['${i}']);
      gp.callMethod('setLabelText', ['']);
      samplePointsRender.add(gp);
    }
  }

  void render() {
    if (opt == null) {
      genDiv.text = 'Generation: -';
      fitDiv.text = 'Best fitness: -';
    } else {
      genDiv.text = 'Generation: ${opt.generation}';
      fitDiv.text = 'Best fitness: ${opt.bestFitness} (from gen. ${opt.bestFitnessGen})';
    }

    if (bsf != null && !wasRendered) {
      //wasRendered = true;
      if (fgraph != null) {
        board.callMethod('removeObject', [fgraph]);
      }

      fgraph = board.callMethod('create', [
        'functiongraph',
        new JsObject.jsify([(x, _) {
          setVars(bsf, x);
          return bsf.eval();
        }, -5, 5]),
        new JsObject.jsify({'strokeColor': '#ffff00'})
      ]);

      texDiv.text = '\$\$ ${bsf.toTex()} \$\$';
      mathJaxProcess(texDiv);
    }
  }

  void finished() {
    print('Finished');
    render();
    startButton.disabled = false;
    cancelButton.disabled = true;

    popSizeInput.disabled = false;
    xoverProbInput.disabled = false;
    mutProbInput.disabled = false;
    tournamentSizeInput.disabled = false;
    elitesNumInput.disabled = false;
    samplePointsNumInput.disabled = false;
  }

  void run() {
    opt.run();
  }

  void cancel() {
    print('Cancelling...');
    opt.cancel();
  }

  num evaluateIndividual(Individual i) {
    Node phenotype = i.root.clone();

    List<num> errs = new List.filled(samplePoints.length, double.NAN);
    for (int n = 0; n < samplePointsNum; n++) {
      num x = samplePoints[n].x;
      num y = samplePoints[n].y;
      setVars(phenotype, x);
      num yhat = phenotype.eval();
      errs[n] = y - yhat;
      if (errs[n].isNaN) {
        return double.INFINITY;
      }
    }

    num err = 0;
    for (int n = 0; n < samplePointsNum; n++) {
      err += errs[n] * errs[n];
    }
    err /= samplePointsNum;
    err = sqrt(err);
    if (err.isNaN || err.isInfinite) {
      return double.INFINITY;
    }

    if (opt.bestFitness == null || err < opt.bestFitness) {
      opt.bestFitness = err;
      opt.bestFitnessGen = opt.generation;
      bsf = phenotype;
      print('New BSF. Solution: ${bsf} Generation: ${opt.generation} Fitness: ${opt.bestFitness} Datapoints: ${errs}');
      wasRendered = false;
    }

    return err;
  }
}