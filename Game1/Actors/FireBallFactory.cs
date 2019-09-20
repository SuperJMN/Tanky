using System;

namespace TankyReloaded.Actors
{
    public class FireBallFactory : WeaponFactory
    {
        public override Shot CreateShot()
        {
            return new FireBall();
        }

        public override TimeSpan ShootingRate => TimeSpan.FromSeconds(0.3);
    }
}