using System;
using Tanky.Actors.Shots;

namespace Tanky.Actors.Weapons
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