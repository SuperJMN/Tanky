using Microsoft.Xna.Framework.Audio;
using SuperJMN.MonoGame;

namespace TankyReloaded.Actors
{
    public abstract class Shot : StageObject
    {
        public abstract int Damage { get; }
        public abstract int HealthPoints { get; set; }
        protected SoundEffect ShootSound;

        private void ReceiveDamage(int damage)
        {
            if (HealthPoints <= 0)
            {
                Destroy();
            }
            else
            {
                HealthPoints -= damage;
            }
        }

        public override void Initialized()
        {
            ShootSound.Play();
        }

        public override void CollideWith(IStageObject other)
        {
            if (other is Bomb)
            {
                Destroy();
            }

            if (other is Ship s)
            {
                ReceiveDamage(s.Damage);
            }
        }

        private void Destroy()
        {
            Stage.Remove(this);
        }
    }
}