using System;

namespace TankyReloaded.Actors
{
    public static class Utils
    {
        public static Random Random = new Random((int) DateTime.Now.Ticks);
    }
}