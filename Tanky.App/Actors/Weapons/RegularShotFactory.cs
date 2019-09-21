using System;
using SuperJMN.MonoGame;
using Tanky.App.Actors.Shots;

namespace Tanky.App.Actors.Weapons
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