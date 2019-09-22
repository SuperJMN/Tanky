using System;
using SuperJMN.MonoGame;
using TankyApp.Actors.Shots;

namespace TankyApp.Actors.Weapons
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