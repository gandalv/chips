function setupMathContent() {
    var $math = $(".math");
    $math.wrapInner("<div class='math-content math-inactive'></div>");
    $math.prepend("<span class='math-warning math-active'>Warning: math content!</span>");
    $math.each(function(i, el) {
        var $c = $(this);
        var $mc = $(".math-content", $c);
        var $mw = $(".math-warning", $c);
        $c.on("click", function() {
            $mc.toggleClass("math-inactive math-active");
            $mw.toggleClass("math-inactive math-active");
        });
    });
});
