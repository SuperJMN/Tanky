using System;
using Tanky.Actors.Shots;

namespace Tanky.Actors.Weapons
{
    public class FireBallFactory : WeaponFactory
    {
        public override Shot CreateShot()
        {
            return new FireBall();
        }

        public override TimeSpan ShootingRate => TimeSpan.FromSeconds(0.35);
    }
}