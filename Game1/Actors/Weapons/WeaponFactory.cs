using System;
using TankyReloaded.Actors.Shots;

namespace TankyReloaded.Actors.Weapons
{
    public abstract class WeaponFactory
    {
        public abstract Shot CreateShot();
        public abstract TimeSpan ShootingRate { get; }
    }
}