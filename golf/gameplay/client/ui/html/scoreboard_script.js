$(document).ready(function() 
{
    // So we can preview in chrome but not mess up ingame
    if (typeof(OOF) == 'undefined')
    {
        OOF = {Subscribe: function(){}}
    }

    let max_holes = 5;
    let my_id = -1;
    let diff;
    let scores;
    let map_data;

    let scoreboard_created = false;

    function CreateScoreboard()
    {
        if (scoreboard_created) {return;}

        if (typeof(scores) == 'undefined' || typeof(map_data) == 'undefined')
        {
            setTimeout(() => {
                CreateScoreboard();
            }, 500);
            return;
        }

        scoreboard_created = true;

        // map_data exists and scores exists
        $('div.scores-container').empty();
        $('div.scoreboard-container').removeClass('Easy')
            .removeClass('Medium')
            .removeClass('Hard')
            .removeClass('Extreme')
            .removeClass('Insane')
            .addClass(diff);

        $('div.scoreboard-container div.scoreboard-top-section div.title').text(map_data.name);
        $('div.scoreboard-container div.scoreboard-top-section div.difficulty').text(diff);

        CreateScoreboardRow("Holes");
        CreateScoreboardRow("Par");

        for (const unique_id in scores.names)
        {
            CreateScoreboardRow(scores.names[unique_id], unique_id);
        }

        
        if (map_data.modded)
        {
            const $elem = $(`<div class='modded top'>Modded</div>`);
            $('div.scoreboard-container').append($elem);
        }
        else
        {
            $('div.scoreboard-container').find('div.modded').remove();
        }

    }

    function CreateScoreboardRow(name, unique_id)
    {
        const id = `holerow_${unique_id == undefined ? name : unique_id}`;
        const $hole_row = $(`<div class='score-row' id='${id}'></div>`);

        if (unique_id == undefined)
        {
            if (name == "Holes")
            {
                $hole_row.addClass('hole')
            }
            else if (name == "Par")
            {
                $hole_row.addClass('par')
            }
        }
        else if (unique_id == my_id)
        {
            $hole_row.addClass('me')
        }

        const $name_col = $(`<div class='score-col name'></div>`);
        $name_col.text(name);
        $hole_row.append($name_col);

        for (let i = 0; i < max_holes; i++)
        {
            let num = "";

            if (unique_id == undefined && name == "Par")
            {
                num = map_data.holes[i].par;
            }
            else if (unique_id == undefined && name == "Holes")
            {
                num = i + 1;
            }

            $hole_row.append($(`<div class='score-col hole holenum${i}'>${num}</div>`));
        }

        if (unique_id == undefined && name == "Par")
        {
            let total = 0;

            for (let i = 0; i < max_holes; i++)
            {
                total = total + map_data.holes[i].par;
            }

            $hole_row.append($(`<div class='score-col total'>${total}</div>`))
        }
        else if (unique_id == undefined && name == "Holes")
        {
            $hole_row.append($(`<div class='score-col total'>Total</div>`))
        }
        else
        {
            $hole_row.append($(`<div class='score-col total'>0</div>`))
        }

        $('div.scores-container').append($hole_row);
    }

    function UpdateScoreboard()
    {
        if (!scoreboard_created)
        {
            setTimeout(() => {
                UpdateScoreboard();
            }, 500);
            return;
        }

        for (const unique_id in scores.names)
        {
            const id = `holerow_${unique_id}`;
            $(`#${id} div.score-col.hole`).removeClass('current')

            const current_hole = scores.current_holes[unique_id] - 1; // 1 indexed per lua
            $(`#${id} div.score-col.hole`).eq(current_hole).addClass('current');

            let total = 0;
            for (let i = 0; i <= Math.min(max_holes - 1, current_hole); i++)
            {
                const score = scores.scores[unique_id][i];
                $(`#${id} div.score-col.hole.holenum${i}`).text(score);
                total += score;
            }

            $(`#${id} div.score-col.total`).text(total);
        }
    }

    OOF.Subscribe('golf/ui/update_scores', (args) => 
    {
        scores = args;

        CreateScoreboard();
        UpdateScoreboard();
    })

    OOF.Subscribe('golf/ui/set_ingame', (args) => 
    {
        scoreboard_created = false;
        map_data = args.map_data;
        diff = args.difficulty;
        max_holes = args.num_holes;

        CreateScoreboard();
    })

    OOF.Subscribe('golf/ui/set_my_id', (args) => 
    {
        my_id = args.id;
    })

    OOF.CallEvent('game/ready')

})
