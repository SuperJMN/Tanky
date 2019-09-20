using System;

namespace TankyReloaded.Actors
{
    public class RegularShotFactory : WeaponFactory
    {
        public override TimeSpan ShootingRate => TimeSpan.FromSeconds(0.15);

        public override Shot CreateShot()
        {
            return new RegularShot();
        }
    }
}