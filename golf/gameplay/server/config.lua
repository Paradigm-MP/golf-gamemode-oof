-- All tables that we're using
GameDBConfig = 
{
    tables = 
    {
        "player_data (unique_id VARCHAR(50) PRIMARY KEY, name VARCHAR(30), model VARCHAR(30), time_online INTEGER, " ..
        "last_login_ip VARCHAR(20), level INTEGER, games_played INTEGER, last_online VARCHAR(20))",
        "bans (unique_id VARCHAR(50) PRIMARY KEY, ban_date VARCHAR(10), reason BLOB)",
        "map_scores (id INTEGER PRIMARY KEY AUTO_INCREMENT, map_name VARCHAR(30), player_data BLOB, wave INTEGER)"
    }
}