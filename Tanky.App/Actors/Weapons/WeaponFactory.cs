using System;
using SuperJMN.MonoGame;
using TankyApp.Actors.Shots;

namespace TankyApp.Actors.Weapons
{
    public abstract class WeaponFactory
    {
        public abstract Shot CreateShot(IStageObject shooter);
        public abstract TimeSpan ShootingRate { get; }
    }
}