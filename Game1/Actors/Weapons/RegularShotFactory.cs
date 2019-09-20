using System;
using TankyReloaded.Actors.Shots;

namespace TankyReloaded.Actors.Weapons
{
    public class RegularShotFactory : WeaponFactory
    {
        public override TimeSpan ShootingRate => TimeSpan.FromSeconds(0.3);

        public override Shot CreateShot()
        {
            return new RegularShot();
        }
    }
}