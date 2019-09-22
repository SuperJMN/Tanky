using System;

namespace TankyApp.Actors.Weapons
{
    public static class WeaponInfoFactory
    {
        public static WeaponFactory Create(int n)
        {
            switch (n)
            {
                case 0:
                    return new SmallShotFactory();
                case 1:
                    return new RegularShotFactory();
                case 2:
                    return new FireBallFactory();
            }

            throw new NotImplementedException("The shot type isn't supported'");
        }
    }
}