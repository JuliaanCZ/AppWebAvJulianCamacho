using System;
using System.Data;

namespace WebAppPoliMusicV2.BLL
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
            return new DAL.Song(strConnectionString).Read();
        }
    }
}
