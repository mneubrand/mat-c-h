var Clay = Clay || {};
Clay.gameKey = "match";
Clay.readyFunctions = [];
Clay.ready = function (fn) {
    Clay.readyFunctions.push(fn);
};
(function () {
    var clay = document.createElement("script");
    clay.src = ( "https:" == document.location.protocol ? "https://" : "http://" ) + "clay.io/api/api.js";
    var tag = document.getElementsByTagName("script")[0];
    tag.parentNode.insertBefore(clay, tag);
})();

soundManager.setup({
    url:'js/vendor',
    flashVersion:9, // optional: shiny features (default = 8)
    useFlashBlock:false, // optionally, enable when you're ready to dive in
    debugFlash:false,
    debugMode:true,

    onready:function () {
        var sounds = [ 'POL-aurora-borealis-short.mp3',
            'electric_alert.mp3',
            'beep.mp3',
            'electric_deny2.mp3',
            'beep2.mp3',
            'simple_click.mp3',
            'blip_click.mp3',
            'xylophone_affirm.mp3',
            'detuned_affirm.mp3' ];

        for (var i = 0; i < sounds.length; i++) {
            soundManager.createSound({
                id:sounds[i].substring(0, sounds[i].indexOf('.')),
                url:'sounds/' + sounds[i],
                autoLoad:true,
                autoPlay:false
            });
        }

        match.soundReady = true;
    }
});

(function () {
    Clay.ready(function () {
        match.clayReady = true;
    })

    var SCALE_WIDTH, SCALE_HEIGHT;
    var OFFSET_X = 0, OFFSET_Y = 0;

    var MODE_CLASSIC = 'Classic';
    var MODE_TEN_NUMBERS = '10 numbers'
    var MODE_ONE_MINUTE = '1 minute drill';

    var leaderboards = {};
    leaderboards[MODE_CLASSIC] = 621;
    leaderboards[MODE_TEN_NUMBERS] = 622;
    leaderboards[MODE_ONE_MINUTE] = 623;

    var POWERUP_SWAP = 'powerup_swap';
    var POWERUP_SKIP = 'powerup_skip';
    var POWERUP_BOMB = 'powerup_bomb';
    var POWERUP_RANDOM = 'powerup_random';
    var powerups = [ POWERUP_SWAP, POWERUP_SKIP, POWERUP_BOMB, POWERUP_RANDOM ];

    var match = {};

    match.getImagePath = function (imageName) {
        return match.highDef ? 'img_hd/' + imageName + '.png' : 'img/' + imageName + '.png';
    }

    match.createSprite = function (scene, imageName) {
        var sprite = scene.Sprite(match.getImagePath(imageName));
        // sprite.scale(match.scaleRatio);
        return sprite;
    }

    match.init = function () {
        // Make canvas fill out the entire screen
        // create the Scene object
        match.scene = sjs.Scene({w:window.innerWidth, h:window.innerHeight});
        match.layer = match.scene.Layer('game', {
            useCanvas:true,
            autoClear:false
        });

        match.highDef = window.innerWidth > 1280;
        SCALE_WIDTH = match.highDef ? 2560 : 1280;
        SCALE_HEIGHT = match.highDef ? 1500 : 750;

        match.scaleLayer(match.layer);

        // load the images in parallel. When all the images are
        // ready, the callback function is called.
        var pictures = [
            match.getImagePath('background'),
            match.getImagePath('header'),
            match.getImagePath('menu_button'),
            match.getImagePath('round_button'),
            match.getImagePath('field_background'),
            match.getImagePath('field_button'),
            match.getImagePath('powerup_button'),
            match.getImagePath('powerup_overlay'),
            match.getImagePath('number_background'),
            match.getImagePath('label_background'),
            match.getImagePath('placeholder'),
            match.getImagePath('guess'),
            match.getImagePath('overlay'),
            match.getImagePath('tutorial_1'),
            match.getImagePath('tutorial_2'),
            match.getImagePath('tutorial_3'),
            match.getImagePath('tutorial_4'),
            match.getImagePath('countdown'),
            match.getImagePath('powerup_swap'),
            match.getImagePath('powerup_skip'),
            match.getImagePath('powerup_bomb'),
            match.getImagePath('powerup_random'),
            match.getImagePath('spark'),
            match.getImagePath('highscores'),
            match.getImagePath('pause'),
            match.getImagePath('dialog'),
            match.getImagePath('dialog_button')
        ];
        match.scene.loadImages(pictures, function () {
            match.initMenu();
        });
    }

    match.scaleLayer = function (layer) {
        var referenceRatio = 1280 / 750;
        var currentRatio = window.innerWidth / window.innerHeight;

        if (referenceRatio < currentRatio) {
            // the reference screen has relatively less height than the current device
            // => height is determining the scale ratio, center horizontally
            match.scaleRatio = window.innerHeight / SCALE_HEIGHT;
            layer.ctx.scale(match.scaleRatio, match.scaleRatio);
            OFFSET_X = (window.innerWidth / match.scaleRatio - SCALE_WIDTH) / 2;
            layer.ctx.translate(OFFSET_X, 0);
        } else {
            // the reference screen has relatively more height than the current device
            // => height is determining the scale ratio, center vertically
            match.scaleRatio = window.innerWidth / SCALE_WIDTH;
            layer.ctx.scale(match.scaleRatio, match.scaleRatio);
            OFFSET_Y = (window.innerHeight / match.scaleRatio - SCALE_HEIGHT) / 2;
            layer.ctx.translate(0, OFFSET_Y);
        }
        console.log("Scale ratio: " + match.scaleRatio);
    }

    match.initMenu = function () {
        // create local variables as shortcuts
        var scene = match.scene;
        var layer = match.layer;

        layer.clear();

        // create the background object;
        var bg = scene.Sprite(match.getImagePath('background'));

        // scale bg image to fit window dimensions
        bg.scale(window.innerWidth / bg.w, window.innerHeight / bg.h);
        bg.update();
        match.bg = bg;

        // create the header
        var header = match.createSprite(layer, 'header');
        header.position((bg.imgNaturalWidth - header.w) / 2, 15);
        header.update();

        // create the menu buttons
        var buttons = [ ];
        var captions = [ MODE_TEN_NUMBERS, MODE_ONE_MINUTE, MODE_CLASSIC ];
        for (var i = 0; i < captions.length; i++) {
            var button = match.initButton('menu_button');
            button.position((bg.imgNaturalWidth - button.w) / 2, bg.imgNaturalHeight - ((button.h + 20) * (i + 1)));
            button.text = captions[i];
            button.cycle.update();
            buttons.push(button);
        }

        var highscore = match.initButton('round_button');
        highscore.position(30, bg.imgNaturalHeight - (highscore.h + 30));
        highscore.label = match.createSprite(layer, 'highscores');
        highscore.onclick = function () {
            match.showHighscores();
        }
        highscore.cycle.update();
        buttons.push(highscore);

        var tutorial = match.initButton('round_button');
        tutorial.position(bg.imgNaturalWidth - (tutorial.w + 30), bg.imgNaturalHeight - (tutorial.h + 30));
        tutorial.label = match.createSprite(layer, 'powerup_random');
        tutorial.onclick = function () {
            match.showTutorial();
        }
        tutorial.cycle.update();
        buttons.push(tutorial);

        // Set up event handling
        layer.dom.onmousedown = function (e) {
            for (var i = 0; i < buttons.length; i++) {
                // If button is pressed animate to pressed state
                var x = e.clientX / match.scaleRatio - OFFSET_X;
                var y = e.clientY / match.scaleRatio - OFFSET_Y;
                if (buttons[i].isPointIn(x, y)) {
                    soundManager.play('simple_click');
                    buttons[i].cycle.go(1);
                    buttons[i].pressed = true;
                    buttons[i].cycle.update();
                }
            }
        }

        layer.dom.onmouseup = function (e) {
            for (var i = 0; i < buttons.length; i++) {
                // Reset button animation
                buttons[i].cycle.go(0);
                buttons[i].pressed = false;
                buttons[i].cycle.update();

                // Start game if we pressed inside button
                var x = e.clientX / match.scaleRatio - OFFSET_X;
                var y = e.clientY / match.scaleRatio - OFFSET_Y;
                if (buttons[i].isPointIn(x, y)) {
                    console.log(soundManager);

                    if (buttons[i].onclick) {
                        buttons[i].onclick();
                    } else {
                        match.gameMode = buttons[i].text;
                        console.log('Starting game in ' + match.gameMode + ' mode');

                        for (var i = 0; i < buttons.length; i++) {
                            buttons[i].remove();
                            header.remove();
                        }
                        match.initGame();
                    }
                }
            }
        }

    }

    match.initButton = function (sprite, layer) {
        layer = layer || match.layer;
        var button = match.createSprite(layer, sprite);
        button.size(button.w / 2, button.h);

        var cycle = match.scene.Cycle([
            [0, 0, 1],
            [button.w, 0, 1]
        ]);
        cycle.addSprite(button);
        return button;
    }

    match.initGame = function () {
        match.initUI();
        match.initPossibilities();
        match.initEventHandling();

        match.gameOver = false;
        match.blocked = true;
        match.selected = [];

        // create countdown
        if (localStorage.getItem('firstRun') === null || localStorage.getItem('firstRun') === true) {
            match.showTutorial(function () {
                match.startCountdown();
            });
        } else {
            match.startCountdown();
        }
    }

    match.startCountdown = function () {
        match.overlay = match.scene.Layer('overlay', {
            useCanvas:true,
            autoClear:false
        });
        match.scaleLayer(match.overlay);
        var countdown = match.createSprite(match.overlay, 'countdown');
        countdown.position((match.bg.imgNaturalWidth - countdown.w) / 2, (match.bg.imgNaturalHeight - countdown.h) / 2);
        countdown.textSize = 350;
        countdown.text = 3;
        countdown.update();

        soundManager.play('beep');
        match.ticker = match.scene.Ticker(function (ticker) {
            if (match.overlay) {
                countdown.text--;
                countdown.update();
                if (countdown.text == 0) {
                    soundManager.play('beep2');
                    match.nextNumber();
                    match.overlay.remove();
                    delete match.overlay;
                } else {
                    soundManager.play('beep');
                }
            } else {
                if (match.gameMode == MODE_TEN_NUMBERS) {
                    match.time.time++;
                } else {
                    match.time.time--;
                }

                var minutes = Math.floor(match.time.time / 60);
                var seconds = match.time.time % 60
                match.time.text = (minutes < 10 ? "0" + minutes : minutes) + ":" + (seconds < 10 ? "0" + seconds : seconds);
                match.time.update();

                if (match.time.time <= 0) {
                    match.time.text = "00:00";
                    match.time.update();
                    match.doGameOver();
                }
            }
        }, { tickDuration:1000 });
        match.ticker.run();
    }

    match.initUI = function () {
        // TODO Animate scene change
        // create local variables as shortcuts
        var layer = match.layer;

        layer.clear();
        match.buttons = [];

        // create field background
        var field = match.createSprite(layer, 'field_background');
        var shadowOffset = 4;
        field.position((match.bg.imgNaturalWidth - field.w) / 2 + shadowOffset, (match.bg.imgNaturalHeight - field.h) / 2 + shadowOffset);
        field.update();
        match.field = field;

        // create field
        for (var i = 0; i < 9; i++) {
            for (var j = 0; j < 9; j++) {
                match.buttons.push(match.initField(layer, j, i));
            }
        }

        // create powerups
        for (var i = 0; i < 4; i++) {
            var powerup = match.createSprite(layer, 'powerup_button');
            powerup.size(powerup.w / 2, powerup.h);
            var offsetY = match.field.y + 80 * (match.highDef ? 2 : 1);
            powerup.position(match.field.x + 18 * (match.highDef ? 2 : 1), offsetY + i * (powerup.h + 40 * (match.highDef ? 2 : 1)));
            powerup.label = match.createSprite(layer, powerups[i]);
            powerup.powerup = powerups[i];

            var cycle = match.scene.Cycle([
                [0, 0, 1],
                [powerup.w, 0, 1]
            ]);
            cycle.addSprite(powerup);
            cycle.update();

            match.buttons.push(powerup);
        }

        // create number/guesses.
        match.guessA = match.initGuess(field.x + 974 * (match.highDef ? 2 : 1), field.y + 220 * (match.highDef ? 2 : 1));
        match.guessB = match.initGuess(field.x + 1126 * (match.highDef ? 2 : 1), field.y + 220 * (match.highDef ? 2 : 1));

        var number = match.createSprite(layer, 'number_background');
        number.position(field.x + 1003 * (match.highDef ? 2 : 1), field.y + 76 * (match.highDef ? 2 : 1));
        number.textClip = true;
        number.textSize = 150;
        number.textFill = '#618207';
        number.update();
        match.number = number;

        // create time and score label
        var time = match.createSprite(layer, 'label_background');
        time.position(field.x + 961 * (match.highDef ? 2 : 1), field.y + 405 * (match.highDef ? 2 : 1));
        time.time = match.gameMode == MODE_TEN_NUMBERS ? 0 : 60;
        time.text = match.gameMode == MODE_TEN_NUMBERS ? 0 : '01:00';
        time.update();
        match.time = time;

        var label = match.createSprite(layer, 'placeholder');
        label.text = 'Time';
        label.textSize = 40;
        label.position(field.x + 1098 * (match.highDef ? 2 : 1), field.y + 380 * (match.highDef ? 2 : 1));
        label.update();

        var score = match.createSprite(layer, 'label_background');
        score.position(field.x + 961 * (match.highDef ? 2 : 1), field.y + 515 * (match.highDef ? 2 : 1));
        score.text = match.gameMode == MODE_TEN_NUMBERS ? 10 : 0;
        score.update();
        match.score = score;

        label = match.createSprite(layer, 'placeholder');
        label.text = match.gameMode == MODE_TEN_NUMBERS ? 'Numbers' : 'Score';
        label.textSize = 40;
        label.position(field.x + 1098 * (match.highDef ? 2 : 1), field.y + 495 * (match.highDef ? 2 : 1));
        label.update();

        // create back to menu button
        var pause = match.createSprite(layer, 'pause');
        pause.position(match.bg.imgNaturalWidth - pause.w - 10 * (match.highDef ? 2 : 1), 10 * (match.highDef ? 2 : 1));

        var cycle = match.scene.Cycle([
            [0, 0, 1],
            [0, 0, 1]
        ]);
        cycle.addSprite(pause);
        cycle.update();
        match.buttons.push(pause);

    }

    match.initGuess = function (x, y) {
        var guess = match.createSprite(match.layer, 'guess');
        guess.size(guess.w / 3, guess.h);
        guess.position(x, y);

        var cycle = match.scene.Cycle([
            [0, 0, 1],
            [guess.w, 0, 1],
            [guess.w * 2, 0, 1]
        ]);
        cycle.addSprite(guess);
        cycle.update();
        return guess;
    }

    match.initEventHandling = function () {
        // create local variables as shortcuts
        var layer = match.layer;

        // Set up event handling
        layer.dom.onmousedown = function (e) {
            if (match.blocked) {
                return;
            }

            for (var i = 0; i < match.buttons.length; i++) {
                // If button is pressed animate to pressed state
                var x = e.clientX / match.scaleRatio - OFFSET_X;
                var y = e.clientY / match.scaleRatio - OFFSET_Y;
                if (match.buttons[i].isPointIn(x, y)) {
                    match.buttons[i].cycle.go(1);
                    match.buttons[i].pressed = true;
                    match.buttons[i].cycle.update();
                    match.pressedButton = match.buttons[i];
                    break;
                }
            }
        }

        layer.dom.onmouseup = function (e) {
            if (match.pressedButton) {
                // Reset button animation
                match.pressedButton.cycle.go(0);
                match.pressedButton.pressed = false;
                match.pressedButton.cycle.update();

                // If up event isn't inside button do nothing
                var x = e.clientX / match.scaleRatio - OFFSET_X;
                var y = e.clientY / match.scaleRatio - OFFSET_Y;
                if (!match.pressedButton.isPointIn(x, y)) {
                    return;
                }

                if (match.pressedButton.powerup) {
                    match.powerupTouched(match.pressedButton);
                } else if (match.pressedButton.field) {
                    match.fieldTouched(match.pressedButton);
                } else {
                    soundManager.play('simple_click');
                    match.pause();
                }

                match.pressedButton = null;
            }
        }
    }

    match.initPossibilities = function () {
        var possibilities = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
            [1, 4, 7],
            [2, 5, 8],
            [3, 6, 9],
            [1, 5, 9],
            [3, 5, 7]
        ];

        var combinations = {};

        // Loop through field
        for (var i = 0; i < 7; i++) {
            for (var j = 0; j < 7; j++) {

                // Loop through all possible combinations
                for (var k = 0; k < possibilities.length; k++) {

                    // Get the 3 involved fields
                    var comps = [];
                    for (var l = 0; l < 3; l++) {
                        var x = i + (possibilities[k][l] - 1) % 3;
                        var y = (j + Math.floor((possibilities[k][l] - 1) / 3)) * 9;
                        comps[l] = match.buttons[x + y].text;
                    }

                    // Compute +/- combinations in both directions
                    combinations[comps[0] * comps[1] + comps[2]] = true;
                    combinations[comps[0] * comps[1] - comps[2]] = true;
                    combinations[comps[2] * comps[1] + comps[0]] = true;
                    combinations[comps[2] * comps[1] - comps[0]] = true;
                    //console.log(comps[0] + "," + comps[1] + "," + comps[2]);
                }
            }
        }

        // Only add positive ones
        match.combinations = [];
        for (var i in combinations) {
            var combination = parseInt(i);
            if (combination > 0) {
                match.combinations.push(combination);
            }
        }
    }

    match.initField = function (layer, x, y) {
        var button = match.createSprite(layer, 'field_button');
        button.size(button.w / 4, button.h);
        button.text = Math.floor(Math.random() * 9) + 1;
        button.field = true;
        button.fieldX = x;
        button.fieldY = y;

        var offsetX = match.field.x + 202 * (match.highDef ? 2 : 1);
        var offsetY = match.field.y + 15 * (match.highDef ? 2 : 1);
        button.position(offsetX + x * (button.w + 6 * (match.highDef ? 2 : 1)), offsetY + y * (button.h + 6 * (match.highDef ? 2 : 1)));

        var cycle = match.scene.Cycle([
            [0, 0, 1],
            [button.w, 0, 1],
            [button.w * 2, 0, 1],
            [button.w * 3, 0, 1]
        ]);
        cycle.addSprite(button);
        cycle.update();
        return button;
    }

    match.fieldTouched = function (field) {
        console.log('Touched field at ' + field.fieldX + ", " + field.fieldY);
        var selected = match.selected;

        if (match.currentPowerup) {
            if (match.currentPowerup.powerup == POWERUP_BOMB) {
                match.powerupBomb(field);
                return;
            } else if (match.currentPowerup.powerup == POWERUP_SWAP) {
                match.powerupSwap(field);
                return;
            }
        }

        // Check double taps
        for (var i = 0; i < selected.length; i++) {
            if (selected[i].fieldX == field.fieldX && selected[i].fieldY == field.fieldY) {
                field.cycle.go(2);
                field.update();
                soundManager.play('blip_click');
                return;
            }
        }

        if (selected.length == 0) {
            match.select(field);
            return;
        } else if (selected.length == 1) {
            //Enforce direction
            if (Math.abs(selected[0].fieldX - field.fieldX) <= 1 && Math.abs(selected[0].fieldY - field.fieldY) <= 1) {
                //Verify that the third option will be available
                var nextX = field.fieldX - (selected[0].fieldX - field.fieldX);
                var nextY = field.fieldY - (selected[0].fieldY - field.fieldY);

                if (nextX >= 0 && nextX < 9 && nextY >= 0 && nextY < 9) {
                    match.select(field);
                    return;
                } else {
                    soundManager.play('electric_alert.wav');
                }
            }
        } else if (selected.length == 2) {
            //Enforce direction
            if (selected[1].fieldX - (selected[0].fieldX - selected[1].fieldX) == field.fieldX
                && selected[1].fieldY - (selected[0].fieldY - selected[1].fieldY) == field.fieldY) {
                match.select(field);
                match.calculateSolution();
                return;
            } else {
                soundManager.play('electric_alert.wav');
            }
        }
    }

    match.select = function (field) {
        field.cycle.go(2);
        field.cycle.update();
        match.selected.push(field);
        soundManager.play('blip_click');
    };

    match.calculateSolution = function () {
        //block UI
        match.blocked = true;

        var selected = match.selected;
        var a = selected[0].text * selected[1].text + selected[2].text;
        var b = selected[0].text * selected[1].text - selected[2].text;
        console.log("Guessed " + a + " and " + b);

        match.guessA.cycle.go(2);
        match.guessB.cycle.go(2);

        if (match.number.text == a || match.number.text == b) {
            // Update guess background
            if (match.number.text == a) {
                match.guessA.cycle.go(1);
            } else if (match.number.text == b) {
                match.guessB.cycle.go(1);
            }

            if (match.gameMode == MODE_TEN_NUMBERS) {
                match.score.text--;
                if (match.score.text == 0) {
                    match.doGameOver();
                }
            } else {
                if (match.gameMode == MODE_CLASSIC) {
                    match.time.time -= Math.max(Math.floor((match.ticker.currentTick - match.lastNumber) / 1.5), 2);
                    match.time.update();
                }
                match.score.text += Math.max(3000 - (match.ticker.currentTick - match.lastNumber) * 100, 100);
            }
            match.score.update();
            soundManager.play('xylophone_affirm');
        } else {
            for (var i = 0; i < selected.length; i++) {
                selected[i].cycle.go(3);
                selected[i].update();
            }
            soundManager.play('electric_deny2');
        }

        // Display guesses
        match.guessA.text = a;
        match.guessB.text = b;

        match.guessA.cycle.update();
        match.guessB.cycle.update();
        match.number.update();

        match.nextNumber();
    }

    match.nextNumber = function () {
        match.blocked = false;
        match.lastNumber = match.ticker.currentTick;

        var newNumber = match.combinations[Math.floor(Math.random() * match.combinations.length)];
        while (newNumber == match.number.text) {
            newNumber = match.combinations[Math.floor(Math.random() * match.combinations.length)];
        }

        match.number.oldText = match.number.text;
        match.number.text = newNumber;
        match.number.textOffset = match.number.w;

        window.setTimeout(function () {
            if (match.gameOver) {
                return;
            }

            for (var i = 0; i < match.selected.length; i++) {
                match.selected[i].cycle.go(0);
                match.selected[i].cycle.update();
            }
            match.selected = [];

            delete match.guessA.text;
            delete match.guessB.text;
            match.guessA.cycle.go(0);
            match.guessB.cycle.go(0);
            match.guessA.cycle.update();
            match.guessB.cycle.update();
            match.number.update();
        }, 600);

        var animate = function (ticker) {
            if (match.gameOver) {
                return;
            }

            match.number.textOffset -= (match.number.w / (400 / 16));
            if (match.number.textOffset >= 0) {
                match.number.update();
                window.setTimeout(animate, 16);
            } else {
                delete match.number.oldText;
                delete match.number.textOffset;
            }
        };
        window.setTimeout(animate, 16);

        match.number.update();

        console.log('New number: ' + newNumber);
    }

    match.doGameOver = function () {
        console.log('Game over');
        match.gameOver = true;
        match.ticker.pause();

        if (match.dialog) {
            return;
        }

        match.initDialog(false);
    }

    match.initDialog = function (paused) {
        match.dialog = match.scene.Layer('dialog', {
            useCanvas:true,
            autoClear:false
        });

        var bg = match.createSprite(match.dialog, 'overlay');
        bg.size(window.innerWidth, window.innerHeight);
        bg.update();

        match.scaleLayer(match.dialog);

        var dialog = match.createSprite(match.dialog, 'dialog');
        dialog.position((match.bg.imgNaturalWidth - dialog.w) / 2, (match.bg.imgNaturalHeight - dialog.h) / 2);
        dialog.update();

        var title = match.createSprite(match.dialog, 'placeholder');
        title.text = paused ? 'Paused' : 'Game Over';
        title.textSize = 90;
        title.position(match.bg.imgNaturalWidth / 2, (match.bg.imgNaturalHeight - dialog.h) / 2 + 70 * (match.highDef ? 2 : 1));
        title.update();

        if (!paused) {
            var totalScore = (match.gameMode == MODE_TEN_NUMBERS ? match.time.time : match.score.text);

            var score = match.createSprite(match.dialog, 'placeholder');
            score.text = 'Score     ' + totalScore;
            score.textSize = 120;
            score.position(match.bg.imgNaturalWidth / 2, (match.bg.imgNaturalHeight - dialog.h) / 2 + 200 * (match.highDef ? 2 : 1));
            score.update();

            var leaderboard = new Clay.Leaderboard({ id:leaderboards[match.gameMode] });
            leaderboard.post({ score:totalScore }, function (response) {
                console.log(response);
            });
        }

        var restart = match.initButton('dialog_button', match.dialog);
        restart.text = paused ? 'resume' : 'restart';
        restart.textSize = 40;
        restart.position((match.bg.imgNaturalWidth - dialog.w) / 2 + 20 * (match.highDef ? 2 : 1), (match.bg.imgNaturalHeight - dialog.h) / 2 + dialog.h - restart.h - 20 * (match.highDef ? 2 : 1));
        restart.update();

        var back = match.initButton('dialog_button', match.dialog);
        back.text = 'back to menu';
        back.textSize = 40;
        back.position((match.bg.imgNaturalWidth - dialog.w) / 2 + dialog.w - back.w - 20 * (match.highDef ? 2 : 1), (match.bg.imgNaturalHeight - dialog.h) / 2 + dialog.h - restart.h - 20 * (match.highDef ? 2 : 1));
        back.update();

        match.dialog.dom.onmousedown = function (e) {
            soundManager.play('simple_click');
            var x = e.clientX / match.scaleRatio - OFFSET_X;
            var y = e.clientY / match.scaleRatio - OFFSET_Y;
            if (restart.isPointIn(x, y)) {
                restart.cycle.go(1);
                restart.cycle.update();
            } else if (back.isPointIn(x, y)) {
                back.cycle.go(1);
                back.cycle.update();
            }
        }

        match.dialog.dom.onmouseup = function (e) {
            var x = e.clientX / match.scaleRatio - OFFSET_X;
            var y = e.clientY / match.scaleRatio - OFFSET_Y;
            if (restart.isPointIn(x, y)) {
                match.dialog.remove();
                delete match.dialog;
                if(paused) {
                    match.ticker.resume();
                } else {
                    match.initGame();
                }
            } else if (back.isPointIn(x, y)) {
                match.dialog.remove();
                delete match.dialog;
                match.initMenu();
            }
        }
    }

    match.powerupTouched = function (powerup) {
        if (powerup.blocked) {
            soundManager.play('electric_alert');
            return;
        }

        if (match.currentPowerup) {
            match.currentPowerup.cycle.go(0);
            match.currentPowerup.update();
            delete match.currentPowerup;

            if (match.swap) {
                match.swap.cycle.go(0);
                match.swap.cycle.update();
                delete match.swap;
            }
        }

        console.log('Touched powerup');
        if (powerup.powerup == POWERUP_RANDOM) {
            match.powerupRandom(powerup);
        } else if (powerup.powerup == POWERUP_BOMB) {
            soundManager.play('blip_click');
            match.currentPowerup = powerup;
            match.currentPowerup.cycle.go(1);
            match.currentPowerup.update();
        } else if (powerup.powerup == POWERUP_SKIP) {
            match.nextNumber();
            match.blockPowerup(powerup);
        } else if (powerup.powerup == POWERUP_SWAP) {
            soundManager.play('blip_click');
            match.currentPowerup = powerup;
            match.currentPowerup.cycle.go(1);
            match.currentPowerup.update();
        }
    }

    match.resetField = function (index) {
        match.buttons[index].cycle.go(2);
        match.buttons[index].label = match.createSprite(match.layer, 'spark');
        match.buttons[index].text = Math.floor(Math.random() * 9) + 1;
        match.buttons[index].update();
    }

    match.resetSelected = function () {
        for (var i = 0; i < match.selected.length; i++) {
            match.selected[i].cycle.go(0);
            match.selected[i].update();
        }
        match.selected = [];
    }

    match.blockPowerup = function (powerup) {
        powerup.blocked = true;
        soundManager.play('detuned_affirm');

        var block = match.createSprite(match.layer, 'powerup_overlay');
        block.position(powerup.x + (powerup.w - block.w) / 2, powerup.y + (powerup.h - block.h) / 2);
        var originalHeight = block.h;
        block.update();

        var currentTick = 0;
        var blockTicker = function (ticker) {
            if (match.gameOver) {
                return;
            }

            block.setH(originalHeight - currentTick * originalHeight / 400);
            powerup.update();
            block.update();
            if (currentTick >= 400) {
                block.remove();
                powerup.blocked = false;
            } else {
                currentTick++;
                window.setTimeout(blockTicker, 100);
            }
        };
        window.setTimeout(blockTicker, 100);
    }

    match.powerupBomb = function (field) {
        match.blocked = true;
        match.resetSelected();
        var buttons = [];
        for (var i = -1; i <= 1; i++) {
            for (var j = -1; j <= 1; j++) {
                if (field.fieldX + i > 8 || field.fieldX + i < 0
                    || field.fieldY + j > 8 || field.fieldY + j < 0) {
                    continue;
                }
                var index = (field.fieldY + j) * 9 + (field.fieldX + i);
                match.resetField(index);
                buttons.push(match.buttons[index]);
            }
        }

        match.initPossibilities();
        window.setTimeout(function () {
            if (match.gameOver) {
                return;
            }

            for (var i = 0; i < buttons.length; i++) {
                buttons[i].cycle.go(0);
                delete buttons[i].label;
                buttons[i].update();
            }
            match.blocked = false;
        }, 600);

        match.currentPowerup.cycle.go(0);
        match.currentPowerup.cycle.update();
        match.blockPowerup(match.currentPowerup);
        delete match.currentPowerup;
    }

    match.powerupRandom = function (powerup) {
        match.blocked = true;
        match.resetSelected();
        var set = {};
        for (var i = 0; i < 9; i++) {
            var index = Math.floor(Math.random() * 9 * 9);
            while (set[index] == true) {
                index = Math.floor(Math.random() * 9 * 9);
            }

            set[index] = true;
            match.resetField(index);
        }
        match.initPossibilities();
        window.setTimeout(function () {
            if (match.gameOver) {
                return;
            }

            for (i in set) {
                match.buttons[i].cycle.go(0);
                delete match.buttons[i].label;
                match.buttons[i].update();
            }
            match.blocked = false;
        }, 600);

        powerup.cycle.go(0);
        powerup.cycle.update();
        match.blockPowerup(powerup);
    }

    match.powerupSwap = function (field) {
        match.resetSelected();
        if (match.swap) {
            match.blocked = true;

            var oldNumber = match.swap.text;
            match.swap.text = field.text;
            field.text = oldNumber;

            match.swap.label = match.createSprite(match.layer, 'spark');
            match.swap.update();

            field.label = match.createSprite(match.layer, 'spark');
            field.cycle.go(2);
            field.update();

            window.setTimeout(function () {
                if (match.gameOver) {
                    return;
                }

                match.swap.cycle.go(0);
                delete match.swap.label;
                match.swap.update();

                field.cycle.go(0);
                delete field.label;
                field.update();

                match.blocked = false;
                delete match.swap;
            }, 600);

            match.currentPowerup.cycle.go(0);
            match.currentPowerup.cycle.update();
            match.blockPowerup(match.currentPowerup);
            delete match.currentPowerup;
        } else {
            soundManager.play('blip_click');
            field.cycle.go(2);
            field.cycle.update();
            match.swap = field;
        }
    }

    match.showTutorial = function (callback) {
        console.log('Show tutorial');
        if (match.tutorial) {
            return;
        }
        localStorage['firstRun'] = false;

        match.tutorial = match.scene.Layer('tutorial', {
            useCanvas:true,
            autoClear:false
        });

        var bg = match.createSprite(match.tutorial, 'overlay');
        bg.size(window.innerWidth, window.innerHeight);
        bg.update();

        match.scaleLayer(match.tutorial);

        var dialog = match.createSprite(match.tutorial, 'tutorial_1');
        dialog.position((match.bg.imgNaturalWidth - dialog.w) / 2, (match.bg.imgNaturalHeight - dialog.h) / 2);
        dialog.update();

        var index = 1;

        match.tutorial.dom.onmouseup = function (e) {
            var x = e.clientX / match.scaleRatio - OFFSET_X;
            var y = e.clientY / match.scaleRatio - OFFSET_Y;
            if (dialog.isPointIn(x, y)) {
                soundManager.play('simple_click');
                if (e.clientX > window.innerWidth / 2) {
                    index++;
                } else {
                    index--;
                }

                if (index <= 4) {
                    if (index < 1) {
                        index = 1;
                    }
                    dialog.loadImg(match.getImagePath('tutorial_' + index));
                    dialog.update();
                } else {
                    match.tutorial.remove();
                    delete match.tutorial;
                    if (callback) {
                        callback();
                    }
                }
            }
        }
    }

    match.showHighscores = function () {
        if (match.clayReady) {
            console.log('Show highscores');
            var id = 621;
            var leaderboard = new Clay.Leaderboard({ id:id });
            leaderboard.setTabs({
                tabs:[
                    { id:622, sort:'asc' },
                    { id:623 }
                ]
            });
            leaderboard.show();
        }
    }

    match.pause = function () {
        match.ticker.pause();

        if (match.dialog) {
            return;
        }

        match.initDialog(true);
    }

    this.match = match;
})();

// use window.load instead of ready so we can guarantee that @font-face is loaded
$(window).bind('load', function () {
    match.init();
});