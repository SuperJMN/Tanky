using System;
using TankyReloaded.Actors.Shots;

namespace TankyReloaded.Actors.Weapons
{
    public class SmallShotFactory : WeaponFactory
    {
        public override Shot CreateShot()
        {
            return new SmallShot();
        }

        public override TimeSpan ShootingRate => TimeSpan.FromSeconds(0.15);
    }
}