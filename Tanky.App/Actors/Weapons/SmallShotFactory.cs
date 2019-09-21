using System;
using SuperJMN.MonoGame;
using Tanky.App.Actors.Shots;

namespace Tanky.App.Actors.Weapons
{
    public class SmallShotFactory : WeaponFactory
    {
        public override Shot CreateShot(IStageObject shooter)
        {
            return new SmallShot(shooter);
        }

        public override TimeSpan ShootingRate => TimeSpan.FromSeconds(0.15);
    }
}