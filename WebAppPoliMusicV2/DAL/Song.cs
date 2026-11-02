using System;
using System.Data;
using System.Data.SqlClient;

namespace WebAppPoliMusicV2.DAL
{
    public class Song
    {
        private readonly string strConnectionString;

        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        public DataTable Read()
        {
            DataTable songs = new DataTable();
            const string query = "SELECT [ID_SONG], [SONG_NAME], [SONG_PATH], " +
                "ISNULL([PLAYS], 0) AS [PLAYS] FROM [dbo].[TBL_SONG] ORDER BY [ID_SONG]";

            using (SqlConnection connection = new SqlConnection(strConnectionString))
            using (SqlCommand command = new SqlCommand(query, connection))
            using (SqlDataAdapter adapter = new SqlDataAdapter(command))
            {
                adapter.Fill(songs);
            }

            return songs;
        }
    }
}
