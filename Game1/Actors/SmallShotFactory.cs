using System;

namespace TankyReloaded.Actors
{
    public class SmallShotFactory : WeaponFactory
    {
        public override Shot CreateShot()
        {
            return new SmallShot();
        }

        public override TimeSpan ShootingRate => TimeSpan.FromSeconds(0.2);
    }
}