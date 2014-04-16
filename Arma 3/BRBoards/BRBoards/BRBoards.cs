﻿using Arma2Net.AddInProxy;
using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace BRBoards
{
    [AddIn("BRBoards")]
    public class BRBoards : MethodAddIn
    {
        // public static string configDir = Directory.GetCurrentDirectory() + @"\BRBoards\";
        public static string configCfg = getDllPath() + "config.ini";
        public static string configLog = getDllPath() + "log.log";

        public static bool isDebug = true;

        private MySqlConnection connection;
        private string server;
        private string database;
        private string uid;
        private string password;
        private string connectionString;

        public void initBoards()
        {
            logCon("Starting BRBoards...");
            if (!Directory.Exists(getDllPath()))
            {
                Directory.CreateDirectory(getDllPath());
                logCon("Created config directory: " + getDllPath());
            }
            if (!File.Exists(getDllPath() + "log.log"))
            {
                File.Create(configLog).Close();
            }
            if (!File.Exists(configCfg))
            {
                File.Create(configCfg).Close();
                logCon("Created config file: " + configCfg);
            }

            server = "localhost";
            database = "brboards";
            uid = "root";
            password = "";
            connectionString = "SERVER=" + server + ";" + "DATABASE=" +
            database + ";" + "UID=" + uid + ";" + "PASSWORD=" + password + ";";
            connection = new MySqlConnection(connectionString);

            if (isDebug)
            {
                logCon("BRBoards is ready!");
            }
        }

        public void logCon(object log)
        {
            if (isDebug)
            {
                TimeSpan timeSpan = new TimeSpan(DateTime.Now.Hour, DateTime.Now.Minute, DateTime.Now.Second);
                StreamWriter logger = new StreamWriter(configLog, true);
                logger.WriteLine(timeSpan + " [BRBoards]: " + log);
                logger.Close();
            }
        }

        public static string getDllPath()
        {
            return Path.GetDirectoryName(new Uri(Assembly.GetExecutingAssembly().CodeBase).LocalPath) + "\\BRBoards\\";
        }

        public string testData(string uid, string wins, string loss, string kills, string deaths)
        {
            uid = uid.Replace("UID", "");
            wins = wins.Replace("WINS", "");
            loss = loss.Replace("LOSS", "");
            kills = kills.Replace("KILLS", "");
            deaths = deaths.Replace("DEATHS", "");

            initBoards();

            logCon("Attempting to send data to the hive...");
            try
            {
                doQuery(0, uid, wins, loss, kills, deaths);
                doQuery(1, uid, wins, loss, kills, deaths);
                logCon("Data sent successfully!");
            }
            catch (Exception ex) { logCon(ex.ToString()); }

            return "Sending to leaderboards: " + uid + ":" + wins + ":" + loss + ":" + kills + ":" + deaths;
        }

        private bool OpenConnection()
        {
            try
            {
                connection.Open();
                logCon("Connected to hive!");
                return true;
            }
            catch (MySqlException ex)
            {
                logCon(ex.Message);
                return false;
            }
        }

        private bool CloseConnection()
        {
            try
            {
                connection.Close();
                logCon("Disconnected from hive!");
                return true;
            }
            catch (MySqlException ex)
            {
                logCon(ex.Message);
                return false;
            }
        }

        public static List<string>[] uidInfo = new List<string>[5];

        public void doQuery(int type, string uid, string wins, string loss, string kills, string deaths)
        {
            switch (type)
            {
                // Generate list of UIDs
                case 0:
                    logCon("Generating a list of UIDs...");
                    uidInfo[0] = new List<string>();
                    uidInfo[1] = new List<string>();
                    uidInfo[2] = new List<string>();
                    uidInfo[3] = new List<string>();
                    uidInfo[4] = new List<string>();
                    string uidInfoQuery = "SELECT * FROM leaderboards;";
                    if (this.OpenConnection() == true)
                    {
                        MySqlCommand cmd = new MySqlCommand(uidInfoQuery, connection);
                        MySqlDataReader dataReader = cmd.ExecuteReader();
                        while (dataReader.Read())
                        {
                            uidInfo[0].Add(dataReader["uid"] + "");
                        }

                        dataReader.Close();
                        this.CloseConnection();
                    }

                    string uidSpecificQuery = "SELECT * FROM leaderboards WHERE uid='" + uid + "';";
                    if (this.OpenConnection() == true)
                    {
                        MySqlCommand cmd = new MySqlCommand(uidSpecificQuery, connection);
                        MySqlDataReader dataReader = cmd.ExecuteReader();
                        while (dataReader.Read())
                        {
                            uidInfo[1].Add(dataReader["wins"] + "");
                            uidInfo[2].Add(dataReader["loss"] + "");
                            uidInfo[3].Add(dataReader["kills"] + "");
                            uidInfo[4].Add(dataReader["deaths"] + "");
                        }

                        dataReader.Close();
                        this.CloseConnection();
                    }
                    break;
                // Insert & Update
                case 1:
                    if (!uidInfo[0].Contains(uid))
                    {
                        string insertQuery = "INSERT INTO leaderboards (uid, wins, loss, kills, deaths) VALUES('" + uid + "', '" + wins + "', '" + loss + "', '" + kills + "', '" + deaths + "');";
                        if (this.OpenConnection() == true)
                        {
                            MySqlCommand cmd = new MySqlCommand(insertQuery, connection);
                            cmd.ExecuteNonQuery();
                            logCon("Sending: " + insertQuery);
                            this.CloseConnection();
                        }
                    }
                    else
                    {
                        logCon("Player UID (" + uid + ") already found... updating instead!");

                        int newWins = int.Parse(uidInfo[1][0]) + int.Parse(wins);
                        int newLoss = int.Parse(uidInfo[2][0]) + int.Parse(loss);
                        int newKills = int.Parse(uidInfo[3][0]) + int.Parse(kills);
                        int newDeaths = int.Parse(uidInfo[4][0]) + int.Parse(deaths);

                        string updateQuery = "UPDATE leaderboards SET wins='" + newWins + "', loss='" + newLoss + "', kills='" + newKills + "', deaths='" + newDeaths + "' WHERE uid='" + uid + "';";
                        if (this.OpenConnection() == true)
                        {
                            MySqlCommand cmd = new MySqlCommand(updateQuery, connection);
                            cmd.ExecuteNonQuery();
                            logCon("Sending: " + updateQuery);
                            this.CloseConnection();
                        }
                    }
                    break;
            }
        }
    }
}