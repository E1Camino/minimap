var lohner = {
  poly: {
    points: [
      [8.85047, -3.24998, 10],
      [3.65326, -7.06038, 10],
      [0.03, -8.284, 12],
      [-6.276, -4.723, 12],
      [-11.6846, -0.0396298, 10],
      [-3.75362, 4.80794, 10],
      [5.44146, 4.16039, 10],
      [6.28618, -0.387159, 10]
    ]
  },

  testPoints: [[5.93141, -5.93644], [5.39529, -5.42156]]
};

var farm = {
  poly: {
    points: [
      [-14.1387, 28.1612, 12],
      [-18.8, 41.6764, 12],
      [-11.9466, 44.2933, 12],
      [-6.77303, 31.1788, 12]
    ]
  },
  testPoints: [
    [-15.57, 36.2, 12],
    [-4, 37, 12],
    [-3.76, 36.09, 12],
    [-10.66, 24.7802, 12]
  ]
};

var pre = function(poly) {
  var X = poly.points.map(p => p[0]);
  var Y = poly.points.map(p => p[1]);

  var constant = [];
  var multiple = [];

  var i;
  var j = X.length - 1;
  for (i = 0; i < X.length; i++) {
    if (Y[j] == Y[i]) {
      constant[i] = X[i];
      multiple[i] = 0;
    } else {
      constant[i] =
        X[i] - (Y[i] * X[j]) / (Y[j] - Y[i]) + (Y[i] * X[i]) / (Y[j] - Y[i]);
      multiple[i] = (X[j] - X[i]) / (Y[j] - Y[i]);
    }
    j = i;
  }
  return Object.assign(poly, {
    X,
    Y,
    constant,
    multiple
  });
};

var check = function({ X, Y, constant, multiple }, point) {
  console.log(point);
  var x = point[0];
  var y = point[1];
  var i;
  var j = X.length - 1;
  var oddNodes = 0;
  for (i = 0; i < X.length; i++) {
    const c1 = Y[i] < y && Y[j] >= y;
    const c2 = Y[j] < y && Y[i] >= y;
    let c3;
    if (c1 || c2) {
      c3 = y * multiple[i] + constant[i] < x;
      oddNodes ^= c3;
    }
    console.log(
      i,
      j,
      c1 ? "c1" : "",
      c2 ? "c2" : "",
      c3 ? "c3" : "",
      oddNodes ? "odd" : ""
    );
    j = i;
  }

  return {
    p: {
      x: point[0],
      y: point[1]
    },
    inside: oddNodes
  };
};

var testPoly = function(name, { poly, testPoints }) {
  console.log("testing poly " + name);
  pre(poly);
  testPoints
    .map(p => check(poly, p))
    .forEach(r => {
      console.log(`point ${r.p.x},${r.p.y} is ${r.inside ? "" : "not"} inside`);
    });
  //console.log(poly);
};

testPoly("lohner", lohner);
//testPoly("farm", farm);
