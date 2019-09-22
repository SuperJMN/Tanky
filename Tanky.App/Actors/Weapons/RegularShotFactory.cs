using System;
using SuperJMN.MonoGame;
using TankyApp.Actors.Shots;

namespace TankyApp.Actors.Weapons
{
    public class RegularShotFactory : WeaponFactory
    {
        public override TimeSpan ShootingRate => TimeSpan.FromSeconds(0.3);

        public override Shot CreateShot(IStageObject shooter)
        {
            return new RegularShot(shooter);
        }
    }
}