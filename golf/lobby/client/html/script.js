$(document).ready(function() 
{
    //$('body').hide()

    $('iframe').attr('src', "http://paradigm.mp/wave-survival-changelog?ts=" + new Date().getTime());

    let course_data = {}
    let queue_data = {}
    let player_data = {}
    let my_id = -1

    let shop_data = {} // Shop items
    let shop_data_map_name_to_id = {}
    let shop_loaded = false

    let map_data_initialized = false

    let selected_course = -1;
    let selected_difficulty = ""
    let highest_unlocked_difficulty = 1;

    const offset = 314; // 2 * pi * r

    const $map_entries = $('div.map-entries')
    const $map_details = $('div.map-details')
    const $map_details_players = $('div.map-details div.map-players')
    const $map_image = $('div.map-image')
    const $players_container = $('div.players-container')
    const $shop_container = $('div.section-skins div.shop-container')
    const $powerups_container = $('div.section-powerups div.shop-container')

    ResetUI();

    let countdown = 
    {
        max: 0,
        current: 0,
        interval: null
    }

    // Play lobby music
    const music = new Audio('http://paradigm.mp/resources/golf/lobbymusic.ogg');
    music.volume = 0.15;
    music.loop = true;
    music.play();

    function ResetUI()
    {
        $('div.countdown-container').hide()

        $map_details_players.empty()
        $players_container.empty()
        $map_entries.empty()
        $shop_container.empty()
        $powerups_container.empty()

        UpdateJoinedAndReadyButtons()
    }

    const countdowns = {}

    class Countdown
    {
        constructor (args)
        {
            this.max_time = args.max_time;
            this.current_time = args.current_time;
            this.course_enum = args.course_enum;
        }

        update (args)
        {
            this.max_time = args.max_time;
            this.current_time = args.current_time;
            this.active = args.active;

            this.clear_timers();
            this.start();
        }

        this_map_selected ()
        {
            return this.course_enum == selected_course;
        }

        clear_timers ()
        {
            if (this.interval != null)
            {
                clearInterval(this.interval)
                this.interval = null;
            }

            if (this.timeout != null)
            {
                clearTimeout(this.timeout);
                this.timeout = null;
            }
        }

        start ()
        {
            if (!this.active)
            {
                this.clear_timers();
                if (this.this_map_selected())
                {
                    $('div.countdown-container').hide();
                }
                return;
            }
            else if (this.active && this.this_map_selected())
            {
                $('div.countdown-container').show();
            }

            this.update_visual_timer(this.current_time, this.current / this.max_time, true)

            if (this.timeout || this.interval)
            {
                this.clear_timers();
            }

            // Do this to get the progress circle moving sooner
            this.timeout = setTimeout(() => {
                this.update_visual_timer(this.current_time, (this.current_time - 1) / this.max_time, false)
                this.timeout = null;
            }, 60);
    
            $(`#mape${this.couse_enum}`).find('div.players-ready-countdown').text(this.current_time > 0 ? this.current_time : "");
            this.interval = setInterval(() => {
                this.current_time -= 1
    
                this.update_visual_timer(this.current_time, (this.current_time - 1) / this.max_time, false)
                $(`#mape${this.course_enum}`).find('div.players-ready-countdown').text(this.current_time > 0 ? this.current_time : "");
                if (this.current_time <= 0)
                {
                    if (this.this_map_selected())
                    {
                        $('div.countdown-container').hide();
                    }
                    clearInterval(this.interval)
                    this.interval = null;
                    this.active = false;
                    return;
                }
    
            }, 1000);
        }

        // Call to update visual timer
        update_visual_timer (time, percent, instant)
        {
            if (!this.this_map_selected())
            {
                return;
            }

            UpdateCountdown(time, percent, instant);
        }
    }

    // Updates the countdown clock
    function UpdateCountdown(time, percent, instant)
    {
        if (instant)
        {
            $('div.countdown-container svg.progress circle.fill').css('transition', 'none');
        }

        $('div.countdown-container div.countdown').text(time);
        $('div.countdown-container svg.progress circle.fill').css("stroke-dashoffset", `${(1 - percent) * offset}%`);

        if (time == 0)
        {
            countdown.timeout = setTimeout(() => {
                $('div.countdown-container').hide()
            }, 1000);
        }

        setTimeout(() => {
            $('div.countdown-container svg.progress circle.fill').css('transition', '1s linear all');
        }, 50);
    }

    // Gets rid of all difficulties so you can add a new one
    function ClearDifficultyClass(elem)
    {
        elem.removeClass('Easy').removeClass('Medium').removeClass('Hard').removeClass('Extreme').removeClass('Insane')
    }

    function FullQueueSync(args)
    {
        queue_data = args;

        // If the maps haven't been loaded yet, wait
        if (!map_data_initialized)
        {
            setTimeout(() => {
                FullQueueSync(args)
            }, 200);
            return;
        }

        // Create player dots for each map
        Object.keys(course_data).forEach((course_enum) => {
            if (queue_data[course_enum])
            {
                CreateSmallMapQueueCircles($(`#mape${course_enum}`), course_enum)
            }
        })

        $('div.countdown-container').hide()
        $map_details_players.empty()
        UpdateJoinedAndReadyButtons()
    }

    const diff_ratings = 
    {
        "Easy": 100,
        "Medium": 200,
        "Hard": 300,
        "Extreme": 400,
        "Insane": 500
    }

    function FullMapSync(args)
    {
        course_data = args

        let map_data_array = []
        
        Object.keys(course_data).forEach((course_enum) => {
            map_data_array.push(course_data[course_enum]);
        })

        map_data_array = map_data_array.sort((a, b) => 
        {
            return a.order - b.order
        })
        
        for (let i = 0; i < map_data_array.length; i++)
        {
            const course_enum = map_data_array[i].course_enum
            CreateMapEntry(map_data_array[i], course_enum)
            AddOrUpdateCountdown({
                course_enum: course_enum,
                current_time: 0,
                max_time: 0,
                active: false
            })
        }

        if (selected_course == -1) {
            SelectMap(2)
        }

        map_data_initialized = true
    }

    function CreateMapEntry(map, course_enum)
    {
        const $elem = $(`<div class='map-entry ${GetDifficultyFromEnum(map.difficulty)}' id='mape${course_enum}'><div class='bg'></div><div class='title'>${map.name}</div>${map.modded ? `<div class='modded'>Modded</div>` : ''}<div class='best-score'></div></div>`)
        CreateSmallMapQueueCircles($elem, course_enum)
        $map_entries.append($elem)
    }

    function CreateSmallMapQueueCircles($map_entry, course_enum)
    {
        $map_entry.find('div.players').remove()
        // Create circles of queued players for each map
        if (queue_data[course_enum])
        {
            Object.keys(queue_data[course_enum]).forEach((difficulty) => {
                if (Object.keys(queue_data[course_enum][difficulty]).length > 0)
                {
                    // Remove ready players element if it already exists
                    $map_entry.remove(`div.players.${difficulty}`);

                    const $difficulty_sec = $(`<div class='players ${difficulty}'>
                    <div class='players-queued-count'></div>
                    <div class='white'>Players</div> 
                    <div class='players-ready-count'>
                        (
                            <div class='count'></div> Ready
                        )
                    </div></div>`)
                    const queued_count = GetNumPlayers(queue_data[course_enum][difficulty]);
                    $difficulty_sec.find('div.players-queued-count').text(queued_count);
                    const ready_count = GetNumReadyPlayers(queue_data[course_enum][difficulty])
                    $difficulty_sec.find('div.players-ready-count div.count').text(ready_count)
                    $difficulty_sec.append($(`<div class='players-ready-countdown'></div>`))

                    $map_entry.append($difficulty_sec)
                }
            });
        }
    }

    function GetNumPlayers(queue)
    {
        let cnt = 0
        for (const index in queue) 
        {
            if (queue.hasOwnProperty(index) && queue[index] != null) 
            {
                cnt++;
            }
        }
        return cnt
    }

    // Gets the number of ready players for a specific queue
    function GetNumReadyPlayers(queue)
    {
        let cnt = 0
        for (const index in queue) 
        {
            if (queue.hasOwnProperty(index) && queue[index] != null) 
            {
                const data = queue[index]
                cnt = (data.ready) ? cnt + 1 : cnt;
            }
        }
        return cnt
    }

    function SingleQueueSync(args)
    {
        queue_data[args.course_enum][args.difficulty] = args.data

        CreateSmallMapQueueCircles($(`#mape${args.course_enum}`), args.course_enum)
        // If they have the map open, update the details
        if (selected_course == args.course_enum)
        {
            GenerateLargePlayerAvatarCircles(args.course_enum)
        }

        UpdateJoinedAndReadyButtons()
    }

    function UpdateJoinedAndReadyButtons()
    {
        $('div.button.map-join').removeClass('selected')
        $('div.button.map-join').removeClass('switch')
        $('div.button.map-ready').removeClass('selected')
        $('div.button.map-join').text('Join')

        Object.keys(queue_data).forEach((course_enum) => {
            Object.keys(queue_data[course_enum]).forEach((difficulty) => {
                if (Object.keys(queue_data[course_enum][difficulty]).length > 0)
                {
                    for (const index in queue_data[course_enum][difficulty]) 
                    {
                        if (queue_data[course_enum][difficulty].hasOwnProperty(index) && queue_data[course_enum][difficulty][index] != null) 
                        {
                            const data = queue_data[course_enum][difficulty][index]

                            if (data.id == my_id)
                            {
                                $('div.button.map-join').addClass('selected')
                                $('div.button.map-join').text('Leave')

                                if (selected_course != course_enum)
                                {
                                    $('div.button.map-join').addClass('switch')
                                    $('div.button.map-join').text('Switch')
                                }

                                if (data.ready)
                                {
                                    $('div.button.map-ready').addClass('selected')
                                }
                            }
                        }
                    }
                }
            })
        })

        UpdateReadyButtonVisibility()
    }

    function UpdateReadyButtonVisibility()
    {
        if ($('div.button.map-join').hasClass('selected'))
        {
            $('div.button.map-ready').show()
        }
        else
        {
            $('div.button.map-ready').hide()
        }
    }

    // Called when a game starts or finishes
    // Currently not being called anymore
    function QueueGameSync(args)
    {
        if (args.start)
        {
            $('div.map-container').hide()
            $('div.map-gameinprogress-container').show()

            // args.mapname, args.difficulty
            $('div.content-container div.map-image div.title').text(args.mapname)
            const $difficulty = $('div.content-container div.map-image div.difficulty')
            ClearDifficultyClass($difficulty)
            $difficulty.addClass(GetDifficultyFromEnum(selected_difficulty))
            $difficulty.text(GetDifficultyFromEnum(args.difficulty)) // TODO: use difficulty name not id, this breaks some CSS styling
            $('div.content-container div.map-image').css('background-image', `url('${course_data[args.mapname].image}')`)
        }
        else
        {
            $('div.map-container').show()
            $('div.map-gameinprogress-container').hide()
        }
    }

    function GetDifficultyFromEnum(difficulty_enum) {
        let difficulty_mapping = {
            1: "Easy",
            2: "Medium",
            3: "Hard",
            4: "Extreme",
            5: "Insane"
        }
        return difficulty_mapping[difficulty_enum]
    }

    function FullPlayersSync(args)
    {
        player_data = args

        for (const player_id in player_data) 
        {
            if (player_data.hasOwnProperty(player_id)) 
            {
                if (player_data[player_id].is_me)
                {
                    my_id = player_id;
                }
                CreatePlayer(player_data[player_id])
            }
        }
        RefreshAllPlayerAvatars()
    }

    function SinglePlayerSync(args)
    {
        if (args.action == "update")
        {
            if ($(`#peplo${args.id}`).length > 0)
            {
                UpdatePlayer(args)
            }
        }
        else if (args.action == "remove")
        {
            $(`#peplo${args.id}`).remove()
        }
        else if (args.action == "add")
        {
            if ($(`#peplo${args.id}`).length == 0)
            {
                CreatePlayer(args)
            }
        }
        RefreshAllPlayerAvatars()
    }

    // Creates a player entry on the left side of lobby
    function CreatePlayer(data)
    {
        const $entry = $(`<div class='players-entry' id='peplo${data.id}'>
            <div class='icon circle rdc${data.id}'></div>
            <div class='name'></div>
            <div class='level'>lvl <div class='val'></div></div>
        </div>`)
        $entry.find('div.icon.circle').css('background-image', data.avatar || '')
        $entry.find('div.name').text(data.name)
        $entry.find('div.level div.val').text(data.level || "?")

        $players_container.append($entry)
    }

    // Comes with avatar, level, 
    function UpdatePlayer(data)
    {
        player_data[data.id] = data
        if (data.avatar)
        {
            $(`div.rdc${data.id}`).css('background-image', `url('${player_data[data.id].avatar || "images/question.png"}')`)
        }

        if (data.level)
        {
            $(`#peplo${data.id}`).find('div.level div.val').text(data.level)
        }
    }

    // Refreshes all player avatars on the right side
    function RefreshAllPlayerAvatars()
    {
        for (const index in player_data) 
        {
            if (player_data.hasOwnProperty(index) && player_data[index] != null) 
            {
                const data = player_data[index]
                $(`div.rdc${data.id}`).css('background-image', `url('${data.avatar || "images/question.png"}')`)
            }
        }
    }

    // Called when the user clicks a top section button to switch
    // section can be LOBBY, SHOP, or LEADERBOARDS
    function SwitchSection(section)
    {
        $('div.section-container').hide()
        $(`div.section-container.section-${section.toLowerCase()}`).show()
    }

    function DisplaySelectedCourseBestScore()
    {
        $.each($("div.map-entry"), function(value, index, arr) {
            let entry_course_enum = parseInt($(this).attr('id').substring(4));
            if (entry_course_enum !== selected_course) {
                $(this).find(".best-score").css("display", "none");
            } else {
                $(this).find(".best-score").css("display", "block");
            }
        });
    }

    function SyncBestScores(args) {
        $.each($("div.map-entry"), function(value, index, arr) {
            let course_enum = parseInt($(this).attr('id').substring(4));

            if (!!args[course_enum]) {
                let best_score_key = "BestCourseScore" + course_enum;
                let best_score_player_key = "BestCourseScorePlayer" + course_enum;
                let best_score_date_key = "BestCourseScoreDate" + course_enum;
                $(this).find(".best-score").html(`Best: <strong>${args[course_enum][best_score_key]}</strong> by <i class='best-score-name'><div><strong>${args[course_enum][best_score_player_key]}</strong></div></i> on <strong>${args[course_enum][best_score_date_key]}</strong>`);
            }
        });

        DisplaySelectedCourseBestScore();
    }

    function SyncHighestDifficulty(args) {
       highest_unlocked_difficulty = args.highest_difficulty_unlocked;

       $.each($("div.map-entry"), function(value, index, arr) {
            let course_enum = parseInt($(this).attr('id').substring(4));
            const title = course_data[course_enum].name;

            if (course_data[course_enum].difficulty > highest_unlocked_difficulty) {
                $(this).find(".title").html(`<span class="locked-title">${title}</span"><span><strong class="locked-text">     Locked</strong></span>`);
            } else {
                $(this).find(".title").html(`${title}`);
            }
        });
    }

    function SelectMap(course_enum)
    {
        const data = course_data[course_enum];
        $("div.map-entry").removeClass("selected")
        $(`#mape${course_enum}`).addClass("selected")
        
        selected_course = course_enum
        selected_difficulty = course_data[course_enum].difficulty
        $map_details.find('div.title').text(data.name)
        let $difficulty = $map_details.find('div.difficulty')
        ClearDifficultyClass($difficulty)
        $difficulty.addClass(GetDifficultyFromEnum(selected_difficulty))
        $difficulty.text(`${GetDifficultyFromEnum(selected_difficulty)} [${data.holes.length}]`)
        
        GenerateLargePlayerAvatarCircles(course_enum)

        // Update map image
        $map_image.css('background-image', `url('${data.image}')`);
        $map_image.find('div.title').text(course_data[course_enum].name)
        $difficulty = $map_image.find('div.difficulty')
        ClearDifficultyClass($difficulty)
        $difficulty.addClass(GetDifficultyFromEnum(selected_difficulty))
        $difficulty.text(GetDifficultyFromEnum(selected_difficulty))

        UpdateJoinedAndReadyButtons()
        DisplaySelectedCourseBestScore();

        OOF.CallEvent('lobby/mapselected');
        
        if (countdowns[selected_course] != null)
        {
            countdowns[selected_course].start()
        }
    }

    function GenerateLargePlayerAvatarCircles(course_enum)
    {
        // Generate circles for players
        $map_details_players.empty()

        if (queue_data[course_enum] && queue_data[course_enum][selected_difficulty])
        {
            for (const index in queue_data[course_enum][selected_difficulty]) 
            {
                if (queue_data[course_enum][selected_difficulty].hasOwnProperty(index) && queue_data[course_enum][selected_difficulty][index] != null) 
                {
                    const data = queue_data[course_enum][selected_difficulty][index]
                    const $elem = $(`<div class='player-entry${data.ready ? ' ready' : ''} rdc${data.id}'></div>`)
                    if (player_data[data.id] != null && player_data[data.id].avatar)
                    {
                        $elem.css('background-image', `url('${player_data[data.id].avatar || "images/question.png"}')`)
                    }
                    $map_details_players.append($elem)
                }
            }
        }
    }

    function JoinLeaveButton(joined)
    {
        OOF.CallEvent('lobby/joinleavebutton', {joined: joined, course_enum: selected_course, difficulty: selected_difficulty});
    }

    function ReadyUpButton(ready)
    {
        OOF.CallEvent('lobby/readyupbutton');
    }

    function GetItemName(item)
    {
        return `${item.model}_${item.outfit}`
    }

    function LoadShopItems(args)
    {
        // Called by the server with info of all the shop items
        shop_data = args;
        shop_data_map_name_to_id = {}

        for (const index in shop_data.skins)
        {
            const item_data = shop_data.skins[index];
            const $entry = $(`<div class='shop-entry' id='SI_${item_data.id}'></div>`);
            $entry.append(`<img class='image' src='http://paradigm.mp/resources/zs/images/${GetItemName(item_data)}.JPG'></img>`);
            $entry.append(`<div class='cost'>${item_data.cost} Points</div>`);
            $entry.append(`<div class='buy-equip'>Buy</div>`);
            $entry.append(`<div class='ownership-indicator'></div>`);
            $entry.data("type", "skins");

            $shop_container.append($entry);

            shop_data_map_name_to_id[GetItemName(item_data)] = item_data.id
        }

        for (const index in shop_data.powerups)
        {
            const item_data = shop_data.powerups[index];
            const $entry = $(`<div class='shop-entry' id='SI_${item_data.id}'></div>`);
            $entry.append(`<img class='image' src='http://paradigm.mp/resources/golf/images/powerup_${item_data.powerup_enum}.png'></img>`);
            $entry.append(`<div class='cost'>${item_data.cost} Points</div>`);
            $entry.append(`<div class='buy-equip'>Buy</div>`);
            $entry.append(`<div class='ownership-indicator'></div>`);
            $entry.data("type", "powerups");

            $powerups_container.append($entry);

            shop_data_map_name_to_id[item_data.name] = item_data.id
        }

        shop_loaded = true
    }

    function ShopNetworkValChanged(args)
    {
        if (!shop_loaded)
        {
            setTimeout(() => {
                ShopNetworkValChanged(args)
            }, 1000);
            return
        }

        if (args.name == "BoughtShopItems")
        {
            // Bought items was updated
            for (const type in args.val)
            {
                for (const index in args.val[type])
                {
                    const item_data = args.val[type][index];
                    const id = shop_data_map_name_to_id[type == "powerups" ? index : GetItemName(item_data)];
                    const $entry = $(`#SI_${id}`);
                    if ($entry && $entry.length > 0)
                    {
                        // Update item entry
                        $entry.removeClass('cant-afford');
                        if (!$entry.hasClass('purchased'))
                        {
                            $entry.addClass('purchased');
                            if (!$entry.hasClass('equipped'))
                            {
                                $entry.find('div.buy-equip').text("EQUIP");
                            }
                        }
                    }
                }
            }
        }
        else if (args.name == "Points")
        {
            $(`.moneydisplay`).text(`${args.val} Points`)
            for (const type in shop_data)
            {
                for (const index in shop_data[type])
                {
                    const item_data = shop_data[type][index];
                    const $entry = $(`#SI_${item_data.id}`);

                    if (!$entry.hasClass('purchased') && !$entry.hasClass('equipped'))
                    {
                        if (!$entry.hasClass('cant-afford') && args.val < item_data.cost)
                        {
                            $entry.addClass('cant-afford')
                        }
                        else if ($entry.hasClass('cant-afford') && args.val >= item_data.cost)
                        {
                            $entry.removeClass('cant-afford')
                        }
                    }
                }
            }
        }
        else if (args.name == "Model")
        {
            args.val = args.val.replace("|", "_").replace(",", "")
            // Player equipped/unequipped a model/outfit (format: MODEL|OUTFITNUMBER)
            for (const index in shop_data.skins)
            {
                const item_data = shop_data.skins[index];

                if (GetItemName(item_data) == args.val)
                {
                    $(`#SI_${item_data.id}`).addClass('equipped')
                    $(`#SI_${item_data.id}`).find('div.buy-equip').text('EQUIPPED')
                }
                else if ($(`#SI_${item_data.id}`).hasClass('equipped'))
                {
                    $(`#SI_${item_data.id}`).removeClass('equipped')
                    $(`#SI_${item_data.id}`).find('div.buy-equip').text('EQUIP')
                }
            }
        }
        else if (args.name == "ActivePowerups")
        {
            // Player equipped/unequipped a model/outfit (format: MODEL|OUTFITNUMBER)
            for (const index in shop_data.powerups)
            {
                const item_data = shop_data.powerups[index];

                if (args.val[item_data.powerup_enum])
                {
                    $(`#SI_${item_data.id}`).addClass('equipped')
                    $(`#SI_${item_data.id}`).find('div.buy-equip').text('EQUIPPED')
                }
                else if ($(`#SI_${item_data.id}`).hasClass('equipped'))
                {
                    $(`#SI_${item_data.id}`).removeClass('equipped')
                    $(`#SI_${item_data.id}`).find('div.buy-equip').text('EQUIP')
                }
            }
        }
    }

    // When they click one of the map buttons
    $(document).on("click", "div.shop-entry div.buy-equip", function() 
    {
        if ($(this).parent().hasClass('cant-afford'))
        {
            return;
        }

        if ($(this).parent().hasClass('purchased'))
        {
            // send request to equip the item
            OOF.CallEvent('lobby/shop/equip_item', {id: $(this).parent().attr('id').replace("SI_", ""), type: $(this).parent().data("type")});
        }
        else
        {
            // send request to buy the item
            OOF.CallEvent('lobby/shop/buy_item', {id: $(this).parent().attr('id').replace("SI_", ""), type: $(this).parent().data("type")});
        }
    })

    // Set section to lobby
    SwitchSection("LOBBY")

    // When they click on the JOIN GAME button to join the already going game
    $(document).on("click", "div.button.clicktojoin", function() 
    {
        OOF.CallEvent('lobby/joinexistinggame');
    })

    $(document).on("click", "div.button.quit-game", function() 
    {
        invokeNative("exit", "")
    })

    // When they click one of the section buttons, change section
    $(document).on("click", "div.title-entry", function() 
    {
        if (!$(this).hasClass("selected"))
        {
            $('div.title-entry').removeClass('selected')
            $(this).addClass('selected')
            SwitchSection($(this).attr('id'))
        }
    })

    // When they click one of the map buttons
    $(document).on("click", "div.map-entry", function() 
    {
        if (!$(this).hasClass("selected"))
        {
            const selected_course_data = course_data[parseInt($(this).attr('id').substring(4))];

            if (selected_course_data.difficulty > highest_unlocked_difficulty) {
                OOF.CallEvent('lobby/select_locked_map', {map_name: selected_course_data.name, current_difficulty: highest_unlocked_difficulty});
                return;
            }

            $("div.map-entry").removeClass("selected")
            $(this).addClass("selected")
            SelectMap(parseInt($(this).attr('id').substring(4)));
        }
    })

    
    // When they click a difficulty
    $(document).on("click", "div.map-difficulty li", function() 
    {
        const $elem_title = $('#dropdown_title')
        $elem_title.removeClass('Easy').removeClass('Medium').removeClass('Hard').removeClass('Extreme').removeClass('Insane')
        $elem_title.addClass($(this).text())
    })

    // When they click to join a map
    $(document).on("click", "div.button.map-join", function() 
    {
        if (button_press_timeout != null) {return;}
        if ($(this).hasClass('selected'))
        {
            $(this).removeClass('selected')
            $(this).text('Join')
        }
        else
        {
            $(this).addClass('selected')
            $(this).text('Leave')
        }
        
        UpdateReadyButtonVisibility()
        JoinLeaveButton($(this).hasClass('selected') || $(this).hasClass('switch'))

        button_press_timeout = setTimeout(() => {
            button_press_timeout = null;
        }, 200);
    })

    let button_press_timeout = null

    // When they click to ready up
    $(document).on("click", "div.button.map-ready", function() 
    {
        if (button_press_timeout != null) {return;}
        if (!$('div.button.map-join').hasClass('selected')) {return;}

        if ($(this).hasClass('selected'))
        {
            $(this).removeClass('selected')
        }
        else
        {
            $(this).addClass('selected')
        }
        ReadyUpButton($(this).hasClass('selected'))
        
        button_press_timeout = setTimeout(() => {
            button_press_timeout = null;
        }, 200);
    })


    $('.dropdown').click(function () {
        $(this).attr('tabindex', 1).focus();
        $(this).toggleClass('active');
        $(this).find('.dropdown-menu').slideToggle(300);
    });
    $('.dropdown').focusout(function () {
        $(this).removeClass('active');
        $(this).find('.dropdown-menu').slideUp(300);
    });
    $('.dropdown .dropdown-menu li').click(function () {
        $(this).parents('.dropdown').find('span').text($(this).text());
        $(this).parents('.dropdown').find('input').attr('value', $(this).attr('id'));
        selected_difficulty = $(this).attr('id')

        let $difficulty = $map_details.find('div.difficulty')
        ClearDifficultyClass($difficulty)
        $difficulty.addClass(GetDifficultyFromEnum(selected_difficulty))
        $difficulty.text(GetDifficultyFromEnum(selected_difficulty))
        
        GenerateLargePlayerAvatarCircles(selected_course)

        $difficulty = $map_image.find('div.difficulty')
        ClearDifficultyClass($difficulty)
        $difficulty.addClass(GetDifficultyFromEnum(selected_difficulty))
        $difficulty.text(GetDifficultyFromEnum(selected_difficulty))

        UpdateJoinedAndReadyButtons()
    });

    function AddOrUpdateCountdown(args)
    {
        if (countdowns[args.course_enum] == null)
        {
            countdowns[args.course_enum] = new Countdown(args);
        }

        countdowns[args.course_enum].update(args);
    }

    OOF.Subscribe('KeyDown', function(key, event)
    {
        if (key == 27) // Escape
        {
            OOF.CallEvent('lobby/esc');
        }
    })

    OOF.Subscribe('lobby/queue/sync/full', function(args)
    {
        FullQueueSync(args);
    })

    OOF.Subscribe('lobby/map/sync/full', function(args)
    {
        FullMapSync(args);
        $('body').show();
    })
    
    OOF.Subscribe('lobby/queue/sync/single', function(args)
    {
        SingleQueueSync(args);
    })
    
    OOF.Subscribe('lobby/players/sync/full', function(args)
    {
        $players_container.empty()
        FullPlayersSync(args)
    })
    
    OOF.Subscribe('lobby/players/sync/single', function(args)
    {
        SinglePlayerSync(args);
    })
    
    OOF.Subscribe('lobby/queue/sync/countdown', function(args)
    {
        AddOrUpdateCountdown(args);
    })

    OOF.Subscribe('lobby/best_scores/sync', function(args)
    {
        SyncBestScores(args);
    })

    OOF.Subscribe('lobby/highest_difficulty/sync', function(difficulty_enum)
    {
        SyncHighestDifficulty(difficulty_enum);
    })
    
    OOF.Subscribe('lobby/queue/sync/countdown/all', function(args)
    {
        for (const course_enum in args)
        {
            AddOrUpdateCountdown(args[course_enum]);
        }
    })
    
    OOF.Subscribe('lobby/queue/sync/game', function(args)
    {
        //QueueGameSync(args);
    })
    
    OOF.Subscribe('lobby/shop/sync/shop_items', function(args)
    {
        LoadShopItems(args);
    })
    
    OOF.Subscribe('lobby/shop/sync/network_val_changed', function(args)
    {
        ShopNetworkValChanged(args);
    })
    
    OOF.Subscribe('Hide', function()
    {
        music.pause();
    })
    
    OOF.Subscribe('Show', function()
    {
        music.play();
    })

    OOF.CallEvent('lobby/ready');
})