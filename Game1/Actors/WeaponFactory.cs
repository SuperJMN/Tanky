using System;

namespace TankyReloaded.Actors
{
    public abstract class WeaponFactory
    {
        public abstract Shot CreateShot();
        public abstract TimeSpan ShootingRate { get; }
    }
}