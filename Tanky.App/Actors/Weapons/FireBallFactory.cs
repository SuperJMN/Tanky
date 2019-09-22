using System;
using SuperJMN.MonoGame;
using TankyApp.Actors.Shots;

namespace TankyApp.Actors.Weapons
{
    public class FireBallFactory : WeaponFactory
    {
        public override Shot CreateShot(IStageObject shooter)
        {
            return new FireBall(shooter);
        }

        public override TimeSpan ShootingRate => TimeSpan.FromSeconds(0.35);
    }
}