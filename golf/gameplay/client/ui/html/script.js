$(document).ready(function() 
{
    // So we can preview in chrome but not mess up ingame
    if (typeof(OOF) == 'undefined')
    {
        OOF = {Subscribe: function(){}}
    }

    const scoring_messages = {
        "-7": "Sextuple Eagle",
        "-6": "Quintuple Eagle",
        "-5": "Quadruple Eagle",
        "-4": "Triple Eagle",
        "-3": "Double Eagle",
        "-2": "Eagle",
        "-1": "Birdie",
        "0": "Par",
        "1": "Bogey",
        "2": "Double Bogey",
        "3": "Triple Bogey",
        "4": "Quadruple Bogey",
        "5": "Quintuple Bogey",
        "6": "Sextuple Bogey"
    }

    const scoring_messages_other = [
        "Nice",
        "Great",
        "Cool",
        "Good",
        "Neat",
        "Way to go",
        "Neato",
        "Solid",
        "Work it",
        "Rad"
    ]

    function GetScoringMessage(strokes, par)
    {
        let message = scoring_messages[(strokes - par).toString()] != undefined ? 
            scoring_messages[(strokes - par).toString()] :
            scoring_messages_other[Math.floor(Math.random() * scoring_messages_other.length)];

        if (strokes == 0)
        {
            return "Hole in Zero";
        }
        else if (strokes == 1)
        {
            return "Hole in One";
        }
        else
        {
            return message;
        }
    }

    $('div.powerup').remove();

    let max_holes = 5;
    let my_id = -1;
    let diff;
    let scores;
    let map_data;

    function AddPowerup(args)
    {   
        if ($(`#powerup_${args.type}`).length > 0)
        {
            $(`#powerup_${args.type}`).remove();
        }

        const $elem = $(`
        <div class='powerup' id='powerup_${args.type}'>
            <svg class='progress'>
                <circle class='background'></circle>
                <circle class='fill'></circle>
            </svg>
            <img class='powerup-img' src='imgs/powerup_${args.type}.png'></img>
        </div>`)

        if (args.key != undefined)
        {
            $elem.append(`<div class='powerup-key text'>${args.key}</div>`);
            if (args.charges != undefined)
            {
                $elem.append(`<div class='powerup-charges text'>${args.charges}</div>`);
            }
        }

        if (args.duration != undefined)
        {
            $elem.find('svg.progress circle.fill').css('transition', `stroke-dashoffset ${args.duration}s linear`);
            
            setTimeout(() => {
                $elem.find('svg.progress circle.fill').css('stroke-dashoffset', `314%`);
            }, 100);
        }

        // Used for armor, progress is 0-1, ex 0.8 is first armor upgrade
        if (args.progress != undefined)
        {
            $elem.find('svg.progress circle.fill').css('transition', `stroke-dashoffset 0.2s ease-in-out`);
            $elem.find('svg.progress circle.fill').css('stroke-dashoffset', `${314 * (1 - args.progress)}%`);
        }

        $('div.powerups-container').append($elem);
    }
    
    OOF.Subscribe('gameplayui/powerup/add', function(args)
    {
        AddPowerup(args);
    })

    const activate_queue = [];
    let activate_timeout = null;

    function ActivatePowerup()
    {
        if (activate_timeout == null && activate_queue.length > 0)
        {
            ShowActivatePowerup(activate_queue.shift());
        }
    }

    function ShowActivatePowerup(name)
    {
        const audio = new Audio('activate_powerup.ogg');
        audio.volume = 0.5;
        audio.play();

        $('div.powerup-activate-title').text(name);
        $('div.powerup-activate-container').css('animation', '0.5s ease-in-out show-powerup');
        $('div.powerup-activate-container').show();
        activate_timeout = setTimeout(() => {
            $('div.powerup-activate-container').css('animation', '1s ease-in-out powerup-grow-shrink infinite');
            activate_timeout = setTimeout(() => {
                $('div.powerup-activate-container').css('animation', '0.5s ease-in-out hide-powerup');
                activate_timeout = setTimeout(() => {
                    $('div.powerup-activate-container').hide();
                    activate_timeout = null;
                    ActivatePowerup();
                }, 500);
            }, 4000);
        }, 500);
    }

    OOF.Subscribe('gameplayui/powerup/activate', function(args)
    {
        activate_queue.push(args.name);
        ActivatePowerup();
    })

    OOF.Subscribe('gameplayui/powerup/modify', function(args)
    {
        if (args.remove)
        {
            $(`#powerup_${args.type}`).remove();
            return;
        }

        if ($(`#powerup_${args.type}`).find('div.powerup-charges'))
        {
            $(`#powerup_${args.type}`).find('div.powerup-charges').text(args.charges)
        }

        if (args.duration != undefined)
        {
            $(`#powerup_${args.type}`).find('svg.progress circle.fill').css('transition', `none`);
            $(`#powerup_${args.type}`).find('svg.progress circle.fill').css('stroke-dashoffset', `314%`);
            setTimeout(() => {
                $(`#powerup_${args.type}`).find('svg.progress circle.fill').css('transition', `stroke-dashoffset ${args.duration}s linear`);
                
                setTimeout(() => {
                    $(`#powerup_${args.type}`).find('svg.progress circle.fill').css('stroke-dashoffset', `0%`);

                    setTimeout(() => {
                        $(`#powerup_${args.type}`).find('svg.progress circle.fill').css('transition', `stroke-dashoffset none`);
                    }, args.duration * 1000);
                }, 100);
            }, 100);
        }
        
        if (args.progress)
        {
            $(`#powerup_${args.type}`).find('svg.progress circle.fill').css('stroke-dashoffset', `${314 * (1 - args.progress)}%`);
        }

    })
    
    // if this doesn't work out for some reason, 
    // change it to text-align center and use transform:translatex to move instead (still have to adjust width)
    function UpdateCurrentHole(hole) // 1 is first hole
    {
        const width = Math.min((100 / ((max_holes - 1) * 1.025)), 100); // IF CIRCLES ARE MISALIGNED, ADJUST THIS
        const progress_width = Math.min(width * (hole - 1) * 1.025, 100);

        $('div.course-progress-inside').css('width', `${progress_width}%`);
        $('div.progress-circle-container').css('width', `${width}%`);

        for (let i = 1; i <= hole; i++)
        {
            if (i == hole) // Current hole
            {
                $(`#pcc_${i}`).children().first().removeClass('current').removeClass('completed').addClass('current');
            }
            else // Completed hole
            {
                $(`#pcc_${i}`).children().first().removeClass('current').removeClass('completed').addClass('completed');
            }
        }
    }

    function DisplayGotHole(strokes, par)
    {
        DisplayNotification(GetScoringMessage(strokes, par));
    }

    function DisplayNotification(text)
    {
        const $elem = $(`<div class='notify-container'>${text}!</div>`);
        $elem.addClass(diff);
        $('body').append($elem);

        setTimeout(() => 
        {
            $elem.remove();
        }, 3000);
    }

    OOF.Subscribe('golf/ui/update_points', (args) =>
    {
        if (args.old_points < args.new_points)
        {
            // Player got points, show notification
            setTimeout(() => {
                DisplayNotification(`+${args.new_points - args.old_points} points`);
            }, 3000);
        }
    })

    OOF.Subscribe('gameplayui/power/set', (args) =>
    {
        $('div.power-bar-inner').css('width', `${Math.min(1, args.power_percent) * 100}%`);
        $('div.power-bar-inner-overflow').css('width', `${Math.max(0, args.power_percent - 1) * 100}%`);
    })

    OOF.Subscribe('golf/ui/update_scores', (args) => 
    {
        // Got to a new hole
        if (scores != undefined)
        {
            const current_hole = scores.current_holes[my_id];
            const next_hole = args.current_holes[my_id];

            if (current_hole < next_hole)
            {
                DisplayGotHole(args.scores[my_id][current_hole - 1], map_data.holes[current_hole - 1].par)
            }
        }

        scores = args;
        UpdateDifficultyAndStrokesText();
    })

    OOF.Subscribe('golf/ui/update_current_hole', (args) => 
    {
        UpdateCurrentHole(args.hole);
        if (args.hole > max_holes)
        {
            $('div.holes').text(`Complete`);
        }
        else
        {
            $('div.holes').text(`Hole ${args.hole}/${max_holes}`);
        }
    })

    OOF.Subscribe('golf/ui/set_ingame', (args) => 
    {
        map_data = args.map_data;
        diff = args.difficulty;

        $('div.top-section').removeClass('Easy');
        $('div.top-section').removeClass('Medium');
        $('div.top-section').removeClass('Hard');
        $('div.top-section').removeClass('Extreme');
        $('div.top-section').removeClass('Insane');
        $('div.top-section').addClass(args.difficulty);
        $('span.title').text(args.name);

        if (args.map_data.modded)
        {
            const $elem = $(`<div class='modded'>Modded</div>`);
            $('div.top-section').append($elem);
        }
        else
        {
            $('div.top-section').find('div.modded').remove();
        }

        max_holes = args.num_holes;
        $('div.progress-circle-container').remove();

        const $progress_container = $('div.course-progress');

        // Create holes in UI
        for (let i = 0; i < args.num_holes; i++)
        {
            const $element = $(`<div class='progress-circle-container' id='pcc_${i+1}'><div class='progress-circle'></div></div>`);

            $progress_container.append($element);
        }

        $('div.holes').text(`Hole 1/${args.num_holes}`);
        $('div.difficulty').text(diff)
        UpdateDifficultyAndStrokesText();

        UpdateCurrentHole(1);
    })

    function UpdateDifficultyAndStrokesText()
    {
        if (typeof(scores) == 'undefined' || typeof(map_data) == 'undefined') {return;}

        const current_hole = scores.current_holes[my_id];

        if (current_hole > map_data.holes.length)
        {
            $('div.tooltip.top').text(`Completed`);
            return;
        }

        const my_score = scores.scores[my_id][current_hole - 1]
        const par = map_data.holes[current_hole - 1].par
        $('div.tooltip.top').text(`Stroke ${my_score} (Par ${par})`);
    }

    OOF.Subscribe('golf/ui/set_my_id', (args) => 
    {
        my_id = args.id;
    })

    OOF.CallEvent('game/ready')

})
