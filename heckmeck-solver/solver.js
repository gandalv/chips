'use strict';

function findAction(saved, thrown) {
    var s = new State(saved, false);
    var root = new StateNode(s, null);
    rollout(root);
}

class StateNode {
    constructor(state, parent) {
        this.state = state;
        this.parent = parent;
        this.children = null;
    }

    rollout() {
        if (this.children == null) {
            generateChanceNodes();
        }
        throw new Error('not implemented');
    }

    generateChanceNodes() {
        if (this.children != null) {
            throw new Error('children already exist');
        }

        var nDice = 8 - sumvals(this.state.saved);
        var roll = new Array(nDice);
        for (var i = 0; i < nDice; i++) {
            roll[i] = 1;
        }
        var next = function(r) {
            var last = true;
            for (var i = 0; i < r.length; i++) {
                r[i] += 1;
                if (r[i] > 6) {
                    r[i] = 1;
                } else {
                    last = false;
                }
            }
            return last;
        }

        var counts = {};
        var total = 0;
        do {
            var key = roll.slice().sort().join('');
            if (counts[key] == undefined) {
                counts[key] = 1;
            } else {
                counts[key] += 1;
            }
            total++;
        } while (next(roll));
    }
}

class ChanceNode {
    constructor(probability, thrown, parent) {
        this.probability = probability;
        this.thrown = thrown;
        this.parent = parent;
        this.children = [];
    }
}

class State {
    constructor(saved, thrown, final) {
        this.saved = Object.assign({}, saved);
        this.thrown = null;
        if (thrown != null && thrown != undefined) {
            this.thrown = Object.assign({}, thrown);
        }
        this.final = final;
    }

    closeAction() {
        return {
            action: 0,
            state: new State(this.saved, true)
        };
    }

    takeActions(thrown) {
        if (this.final) {
            return [];
        }

        if (sumvals(this.saved) + sumvals(thrown) != 8) {
            throw new Error('invalid number of dice');
        }

        var ret = [];
        for (const [n, cnt] of Object.entries(thrown)) {
            if (n in this.saved) {
                continue;
            }

            var nextState = new State(this.saved, false);
            nextState.saved[n] = cnt;
            ret.push({
                action: n,
                state: nextState
            });
        }

        return ret;
    }
}

function sumvals(obj) {
    var s = 0;
    for (var k in obj) {
        s += obj[k];
    }
    return s;
}

function getNums(r) {
    var ret = {};
    for (var k of r) {
        if (ret[k] == undefined) {
            ret[k] = 1;
        } else {
            ret[k] += 1;
        }
    }
    return ret;
}